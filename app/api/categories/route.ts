import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";
import Category from "@/model/Category";
import { handleApiError } from "@/lib/api-error";

// GET /api/categories
//
// Returns an array of categories directly as JSON, sorted by sortOrder ascending.
// Public endpoint with caching matching /api/menu.
export async function GET() {
  try {
    await connectDB();

    const categoriesDoc = await Category.find({ slug: { $ne: "all" } })
      .sort({ sortOrder: 1 })
      .lean();

    const categories = categoriesDoc.map((cat) => ({
      id: cat._id.toString(),
      _id: cat._id.toString(),
      name: cat.name,
      slug: cat.slug,
      icon: cat.icon ?? "",
      sortOrder: cat.sortOrder ?? 0,
    }));

    return NextResponse.json(categories, {
      headers: {
        "Cache-Control": "public, max-age=60, stale-while-revalidate=300",
      },
    });
  } catch (err) {
    return handleApiError(err);
  }
}
