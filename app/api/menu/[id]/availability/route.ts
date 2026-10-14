import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { connectDB } from "@/lib/db";
import MenuItem from "@/model/MenuItem";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

interface RouteContext {
  params: Promise<{ id: string }>;
}

// PATCH /api/menu/:id/availability (admin only)
// Updates only the `available` status of a MenuItem document in MongoDB.
export async function PATCH(request: Request, context: RouteContext) {
  try {
    await requireAdmin(request);
    await connectDB();

    const { id } = await context.params;

    if (!id || !mongoose.isValidObjectId(id)) {
      throw new ApiError(
        404,
        "NOT_FOUND",
        `Menu item with id '${id}' not found.`,
      );
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

    const { available } = body as Record<string, unknown>;

    if (available === undefined || typeof available !== "boolean") {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'available' is required and must be a boolean.",
      );
    }

    const updatedItem = await MenuItem.findByIdAndUpdate(
      id,
      { $set: { available } },
      { new: true, runValidators: true },
    ).lean();

    if (!updatedItem) {
      throw new ApiError(
        404,
        "NOT_FOUND",
        `Menu item with id '${id}' not found.`,
      );
    }

    return NextResponse.json({
      id: updatedItem._id.toString(),
      _id: updatedItem._id.toString(),
      name: updatedItem.name,
      subtitle: updatedItem.subtitle,
      price: updatedItem.price,
      rating: updatedItem.rating,
      categorySlug: updatedItem.categorySlug,
      type: updatedItem.type,
      featured: updatedItem.featured,
      image: updatedItem.image,
      available: updatedItem.available,
      createdAt: updatedItem.createdAt,
      updatedAt: updatedItem.updatedAt,
    });
  } catch (err) {
    return handleApiError(err);
  }
}
