import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { connectDB } from "@/lib/db";
import MenuItem from "@/model/MenuItem";
import Category from "@/model/Category";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

interface RouteContext {
  params: Promise<{ id: string }>;
}

// PUT /api/menu/:id (admin only)
// Updates an existing MenuItem document in MongoDB.
export async function PUT(request: Request, context: RouteContext) {
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

    const {
      name,
      subtitle,
      price,
      rating,
      categorySlug,
      type,
      featured,
      image,
      available,
    } = body as Record<string, unknown>;

    const updateData: Record<string, unknown> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || !name.trim()) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'name' must be a non-empty string.",
        );
      }
      updateData.name = name.trim();
    }

    if (subtitle !== undefined) {
      if (typeof subtitle !== "string" || !subtitle.trim()) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'subtitle' must be a non-empty string.",
        );
      }
      updateData.subtitle = subtitle.trim();
    }

    if (price !== undefined) {
      if (typeof price !== "number" || !Number.isFinite(price) || price < 0) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'price' must be a non-negative number.",
        );
      }
      updateData.price = price;
    }

    if (rating !== undefined) {
      if (
        typeof rating !== "number" ||
        !Number.isFinite(rating) ||
        rating < 0 ||
        rating > 5
      ) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'rating' must be a number between 0 and 5.",
        );
      }
      updateData.rating = rating;
    }

    if (categorySlug !== undefined) {
      if (typeof categorySlug !== "string" || !categorySlug.trim()) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'categorySlug' must be a non-empty string.",
        );
      }
      const categoryExists = await Category.exists({
        slug: categorySlug.trim(),
      });
      if (!categoryExists) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          `Category with slug '${categorySlug}' does not exist.`,
        );
      }
      updateData.categorySlug = categorySlug.trim();
    }

    if (type !== undefined) {
      if (type !== "veg" && type !== "non-veg") {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'type' must be either 'veg' or 'non-veg'.",
        );
      }
      updateData.type = type;
    }

    if (featured !== undefined) {
      if (typeof featured !== "boolean") {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'featured' must be a boolean.",
        );
      }
      updateData.featured = featured;
    }

    if (image !== undefined) {
      if (typeof image !== "string" || !image.trim()) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'image' must be a non-empty string.",
        );
      }
      updateData.image = image.trim();
    }

    if (available !== undefined) {
      if (typeof available !== "boolean") {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'available' must be a boolean.",
        );
      }
      updateData.available = available;
    }

    if (Object.keys(updateData).length === 0) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "No valid update fields provided.",
      );
    }

    const updatedItem = await MenuItem.findByIdAndUpdate(
      id,
      { $set: updateData },
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

// DELETE /api/menu/:id (admin only)
// Deletes a MenuItem document from MongoDB.
export async function DELETE(request: Request, context: RouteContext) {
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

    const deletedItem = await MenuItem.findByIdAndDelete(id).lean();

    if (!deletedItem) {
      throw new ApiError(
        404,
        "NOT_FOUND",
        `Menu item with id '${id}' not found.`,
      );
    }

    return NextResponse.json({ deleted: true, id }, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}

