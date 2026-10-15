import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";
import Admin from "@/model/Admin";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

// POST /api/admin/fcm-token (admin only)
// Registers or updates an FCM device token on the Admin document.
export async function POST(request: Request) {
  try {
    const adminPayload = await requireAdmin(request);
    await connectDB();

    const body = await request.json().catch(() => null);
    if (!body || typeof body !== "object") {
      throw new ApiError(400, "BAD_REQUEST", "Invalid request payload.");
    }

    const token = (body.token ?? body.fcmToken) as unknown;
    if (!token || typeof token !== "string" || !token.trim()) {
      throw new ApiError(
        400,
        "BAD_REQUEST",
        "FCM token must be a non-empty string.",
      );
    }

    const trimmedToken = token.trim();

    // Add token to the admin document if not already present
    let updatedAdmin = await Admin.findOneAndUpdate(
      { _id: adminPayload.id },
      { $addToSet: { fcmTokens: trimmedToken } },
      { new: true },
    );

    if (!updatedAdmin) {
      // Fallback by username if id in token did not match
      updatedAdmin = await Admin.findOneAndUpdate(
        { username: adminPayload.username },
        { $addToSet: { fcmTokens: trimmedToken } },
        { new: true },
      );
    }

    if (!updatedAdmin) {
      throw new ApiError(404, "NOT_FOUND", "Admin user not found.");
    }

    return NextResponse.json(
      {
        success: true,
        message: "FCM token registered successfully.",
      },
      { status: 200 },
    );
  } catch (err) {
    return handleApiError(err);
  }
}
