import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { connectDB } from "@/lib/db";
import Order from "@/model/Order";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";
import { assertValidTransition } from "@/lib/order-transitions";

interface RouteContext {
  params: Promise<{ id: string }>;
}

// PATCH /api/orders/:id/reject (admin only)
// Transitions order from pending -> rejected
export async function PATCH(request: Request, context: RouteContext) {
  try {
    await requireAdmin(request);
    await connectDB();

    const { id } = await context.params;

    if (!id || !mongoose.isValidObjectId(id)) {
      throw new ApiError(404, "NOT_FOUND", `Order with id '${id}' not found.`);
    }

    const order = await Order.findById(id);

    if (!order) {
      throw new ApiError(404, "NOT_FOUND", `Order with id '${id}' not found.`);
    }

    assertValidTransition(order.status, "rejected");

    order.status = "rejected";
    await order.save();

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
      { status: 200 },
    );
  } catch (err) {
    return handleApiError(err);
  }
}
