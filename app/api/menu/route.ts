import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";
import Category from "@/model/Category";
import MenuItem from "@/model/MenuItem";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

// GET /api/menu
// GET /api/menu?category=sandwitch
// GET /api/menu?type=veg
// GET /api/menu?available=true
//
// Returns { categories, items }. Query params are optional and combine
// (AND logic). Intended to be consumed by other apps/clients, not just
// this Next.js app.
export async function GET(request: Request) {
  try {
    await connectDB();

    const { searchParams } = new URL(request.url);
    const category = searchParams.get("category");
    const type = searchParams.get("type");
    const available = searchParams.get("available");

    const query: Record<string, unknown> = {};

    if (category && category !== "all") {
      query.categorySlug = category;
    }
    if (type === "veg" || type === "non-veg") {
      query.type = type;
    }
    if (available === "true") {
      query.available = true;
    } else if (available === "false") {
      query.available = false;
    }

    const [categoriesDoc, itemsDoc] = await Promise.all([
      Category.find({ slug: { $ne: "all" } })
        .sort({ sortOrder: 1 })
        .lean(),
      MenuItem.find(query).lean(),
    ]);

    const categories = categoriesDoc.map((cat) => ({
      id: cat._id.toString(),
      _id: cat._id.toString(),
      name: cat.name,
      slug: cat.slug,
      icon: cat.icon ?? "",
    }));

    const items = itemsDoc.map((item) => ({
      id: item._id.toString(),
      _id: item._id.toString(),
      name: item.name,
      subtitle: item.subtitle,
      price: item.price,
      rating: item.rating,
      categorySlug: item.categorySlug,
      type: item.type,
      featured: item.featured,
      image: item.image,
      available: item.available,
    }));

    return NextResponse.json(
      { categories, items },
      {
        headers: {
          "Cache-Control": "public, max-age=60, stale-while-revalidate=300",
        },
      },
    );
  } catch (err) {
    return handleApiError(err);
  }
}

// POST /api/menu (admin only)
// Creates a new MenuItem document in MongoDB.
export async function POST(request: Request) {
  try {
    await requireAdmin(request);
    await connectDB();

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      throw new ApiError(400, "VALIDATION_ERROR", "Invalid JSON body.");
    }

    if (!body || typeof body !== "object" || Array.isArray(body)) {
      throw new ApiError(400, "VALIDATION_ERROR", "Request body must be a JSON object.");
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

    if (name === undefined || typeof name !== "string" || !name.trim()) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'name' is required and must be a non-empty string.",
      );
    }

    if (subtitle === undefined || typeof subtitle !== "string" || !subtitle.trim()) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'subtitle' is required and must be a non-empty string.",
      );
    }

    if (typeof price !== "number" || !Number.isFinite(price) || price < 0) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'price' is required and must be a non-negative number.",
      );
    }

    if (
      typeof rating !== "number" ||
      !Number.isFinite(rating) ||
      rating < 0 ||
      rating > 5
    ) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'rating' is required and must be a number between 0 and 5.",
      );
    }

    if (
      categorySlug === undefined ||
      typeof categorySlug !== "string" ||
      !categorySlug.trim()
    ) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'categorySlug' is required and must be a non-empty string.",
      );
    }

    if (type !== "veg" && type !== "non-veg") {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'type' is required and must be either 'veg' or 'non-veg'.",
      );
    }

    if (image === undefined || typeof image !== "string" || !image.trim()) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'image' is required and must be a non-empty string.",
      );
    }

    if (featured !== undefined && typeof featured !== "boolean") {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'featured' must be a boolean.",
      );
    }

    if (available !== undefined && typeof available !== "boolean") {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        "Field 'available' must be a boolean.",
      );
    }

    const categoryExists = await Category.exists({ slug: categorySlug.trim() });
    if (!categoryExists) {
      throw new ApiError(
        400,
        "VALIDATION_ERROR",
        `Category with slug '${categorySlug}' does not exist.`,
      );
    }

    const newItem = await MenuItem.create({
      name: name.trim(),
      subtitle: subtitle.trim(),
      price,
      rating,
      categorySlug: categorySlug.trim(),
      type,
      featured: typeof featured === "boolean" ? featured : false,
      image: image.trim(),
      available: typeof available === "boolean" ? available : true,
    });

    return NextResponse.json(
      {
        id: newItem._id.toString(),
        _id: newItem._id.toString(),
        name: newItem.name,
        subtitle: newItem.subtitle,
        price: newItem.price,
        rating: newItem.rating,
        categorySlug: newItem.categorySlug,
        type: newItem.type,
        featured: newItem.featured,
        image: newItem.image,
        available: newItem.available,
        createdAt: newItem.createdAt,
        updatedAt: newItem.updatedAt,
      },
      { status: 201 },
    );
  } catch (err) {
    return handleApiError(err);
  }
}

