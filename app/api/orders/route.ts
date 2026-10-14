import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { auth } from "@/auth";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import MenuItem from "@/model/MenuItem";
import Order, { IOrderItem } from "@/model/Order";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

// POST /api/orders (customer session)
// Places a new order, validating items against DB prices and availability.
export async function POST(request: Request) {
  try {
    const session = await auth();

    if (!session?.user?.id) {
      throw new ApiError(401, "UNAUTHORIZED", "Not signed in.");
    }

    await connectDB();

    if (!mongoose.isValidObjectId(session.user.id)) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    const customer = await Customer.findById(session.user.id).lean();

    if (!customer) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      throw new ApiError(400, "VALIDATION_ERROR", "Invalid JSON body.");
    }

    if (!body || typeof body !== "object" || Array.isArray(body)) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Request body must be a JSON object.",
      );
    }

    const { items, fulfillment, tableNumber } = body as Record<string, unknown>;

    if (fulfillment !== "dine-in" && fulfillment !== "pickup") {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'fulfillment' must be 'dine-in' or 'pickup'.",
      );
    }

    const cleanTableNumber =
      fulfillment === "dine-in" &&
      typeof tableNumber === "string" &&
      tableNumber.trim()
        ? tableNumber.trim()
        : undefined;

    if (!Array.isArray(items) || items.length === 0) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'items' must be a non-empty array.",
      );
    }

    const snapshottedItems: IOrderItem[] = [];
    let itemTotal = 0;

    for (const rawItem of items) {
      if (!rawItem || typeof rawItem !== "object" || Array.isArray(rawItem)) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Each item in 'items' must be an object.",
        );
      }

      const { menuItemId, quantity } = rawItem as Record<string, unknown>;

      if (
        typeof quantity !== "number" ||
        !Number.isInteger(quantity) ||
        quantity <= 0
      ) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Each item quantity must be a positive integer.",
        );
      }

      if (
        !menuItemId ||
        typeof menuItemId !== "string" ||
        !mongoose.isValidObjectId(menuItemId)
      ) {
        throw new ApiError(
          409,
          "ITEM_UNAVAILABLE",
          "One or more items in your cart are no longer available.",
        );
      }

      const menuItem = await MenuItem.findById(menuItemId).lean();

      if (!menuItem || menuItem.available === false) {
        throw new ApiError(
          409,
          "ITEM_UNAVAILABLE",
          "One or more items in your cart are no longer available.",
        );
      }

      snapshottedItems.push({
        menuItemId: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        quantity,
      });

      itemTotal += menuItem.price * quantity;
    }

    const order = await Order.create({
      customerId: customer._id,
      customerName: customer.name,
      fulfillment,
      ...(cleanTableNumber ? { tableNumber: cleanTableNumber } : {}),
      items: snapshottedItems,
      itemTotal,
      total: itemTotal,
      status: "pending",
      placedAt: new Date(),
    });

    return NextResponse.json(
      {
        id: order._id.toString(),
        _id: order._id.toString(),
        customerId: order.customerId.toString(),
        customerName: order.customerName,
        fulfillment: order.fulfillment,
        ...(order.tableNumber ? { tableNumber: order.tableNumber } : {}),
        items: order.items.map((it) => ({
          _id: it._id?.toString(),
          menuItemId: it.menuItemId.toString(),
          name: it.name,
          price: it.price,
          quantity: it.quantity,
        })),
        itemTotal: order.itemTotal,
        total: order.total,
        status: order.status,
        placedAt: order.placedAt,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      },
      { status: 201 },
    );
  } catch (err) {
    return handleApiError(err);
  }
}

// GET /api/orders (admin)
// Query params: status?: "pending" | "accepted" | "completed" | "rejected", limit?: number, skip?: number
// Returns { orders: [...], total: number }
export async function GET(request: Request) {
  try {
    await requireAdmin(request);
    await connectDB();

    const { searchParams } = new URL(request.url);
    const statusParam = searchParams.get("status");

    const VALID_STATUSES = [
      "pending",
      "accepted",
      "completed",
      "rejected",
    ] as const;

    const filter: Record<string, unknown> = {};

    if (statusParam !== null) {
      if (
        !VALID_STATUSES.includes(
          statusParam as (typeof VALID_STATUSES)[number],
        )
      ) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'status' must be one of 'pending', 'accepted', 'completed', or 'rejected'.",
        );
      }
      filter.status = statusParam;
    }

    const limitParam = searchParams.get("limit");
    const skipParam = searchParams.get("skip");

    let limit = 50;
    if (limitParam !== null) {
      const parsed = parseInt(limitParam, 10);
      if (!isNaN(parsed) && parsed > 0) {
        limit = Math.min(Math.max(1, parsed), 100);
      }
    }

    let skip = 0;
    if (skipParam !== null) {
      const parsed = parseInt(skipParam, 10);
      if (!isNaN(parsed) && parsed >= 0) {
        skip = parsed;
      }
    }

    const [ordersDoc, total] = await Promise.all([
      Order.find(filter)
        .sort({ placedAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    const formattedOrders = ordersDoc.map((order) => ({
      id: order._id.toString(),
      _id: order._id.toString(),
      customerId: order.customerId.toString(),
      customerName: order.customerName,
      fulfillment: order.fulfillment,
      ...(order.tableNumber ? { tableNumber: order.tableNumber } : {}),
      items: order.items.map((it) => ({
        _id: it._id?.toString(),
        menuItemId: it.menuItemId.toString(),
        name: it.name,
        price: it.price,
        quantity: it.quantity,
      })),
      itemTotal: order.itemTotal,
      total: order.total,
      status: order.status,
      placedAt: order.placedAt,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    }));

    return NextResponse.json({
      orders: formattedOrders,
      total,
    });
  } catch (err) {
    return handleApiError(err);
  }
}
