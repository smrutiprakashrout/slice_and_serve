import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { auth } from "@/auth";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import Order from "@/model/Order";
import { ApiError, handleApiError } from "@/lib/api-error";

// GET /api/orders/me (customer session)
// Returns all orders belonging to the currently signed-in customer, newest first.
export async function GET() {
  try {
    const session = await auth();

    if (!session) {
      throw new ApiError(401, "UNAUTHORIZED", "Not signed in.");
    }
    if (!session.user?.id) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
    }

    await connectDB();

    if (!mongoose.isValidObjectId(session.user.id)) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
    }

    const customer = await Customer.findById(session.user.id).lean();

    if (!customer) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
    }

    const orders = await Order.find({ customerId: customer._id })
      .sort({ placedAt: -1 })
      .lean();

    return NextResponse.json(
      orders.map((order) => ({
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
      })),
    );
  } catch (err) {
    return handleApiError(err);
  }
}
