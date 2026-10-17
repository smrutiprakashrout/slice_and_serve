import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { auth } from "@/auth";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";
import Order from "@/model/Order";
import { ApiError, handleApiError } from "@/lib/api-error";

// GET /api/me (customer session)
// Returns the profile of the currently signed-in customer.
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

    return NextResponse.json({
      id: customer._id.toString(),
      _id: customer._id.toString(),
      name: customer.name,
      email: customer.email,
      photo: customer.photo,
      preferences: customer.preferences,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    });
  } catch (err) {
    return handleApiError(err);
  }
}

// PATCH /api/me (customer session)
// Updates preferences for the currently signed-in customer.
export async function PATCH(request: Request) {
  try {
    const session = await auth();

    if (!session) {
      throw new ApiError(401, "UNAUTHORIZED", "Not signed in.");
    }
    if (!session.user?.id) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
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

    const { preferences } = body as Record<string, unknown>;

    const updateFields: Record<string, unknown> = {};

    if (preferences !== undefined) {
      if (
        !preferences ||
        typeof preferences !== "object" ||
        Array.isArray(preferences)
      ) {
        throw new ApiError(
          400,
          "VALIDATION_ERROR",
          "Field 'preferences' must be an object.",
        );
      }

      const prefObj = preferences as Record<string, unknown>;
      const allowedKeys = ["vegOnly", "orderUpdates", "offers", "newItems"];

      for (const [key, val] of Object.entries(prefObj)) {
        if (typeof val !== "boolean") {
          throw new ApiError(
            400,
            "VALIDATION_ERROR",
            `Preference field '${key}' must be a boolean.`,
          );
        }
        if (allowedKeys.includes(key)) {
          updateFields[`preferences.${key}`] = val;
        }
      }
    }

    await connectDB();

    if (!mongoose.isValidObjectId(session.user.id)) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
    }

    const updatedCustomer =
      Object.keys(updateFields).length > 0
        ? await Customer.findByIdAndUpdate(
            session.user.id,
            { $set: updateFields },
            { new: true, runValidators: true },
          ).lean()
        : await Customer.findById(session.user.id).lean();

    if (!updatedCustomer) {
      throw new ApiError(401, "SESSION_INVALID", "Your session is no longer valid. Please sign in again.");
    }

    return NextResponse.json({
      id: updatedCustomer._id.toString(),
      _id: updatedCustomer._id.toString(),
      name: updatedCustomer.name,
      email: updatedCustomer.email,
      photo: updatedCustomer.photo,
      preferences: updatedCustomer.preferences,
      createdAt: updatedCustomer.createdAt,
      updatedAt: updatedCustomer.updatedAt,
    });
  } catch (err) {
    return handleApiError(err);
  }
}

// DELETE /api/me (customer session)
// Permanently deletes the customer's account and loyalty card, and anonymizes order history.
export async function DELETE() {
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

    const customer = await Customer.findById(session.user.id);

    if (!customer) {
      return NextResponse.json({ deleted: true });
    }

    // Deletion order chosen for least damage on partial failure:
    // 1. Anonymize orders first: preserves business history while scrubbing personal name.
    // If subsequent steps fail, customer PII is already scrubbed from business records.
    await Order.updateMany(
      { customerId: customer._id },
      { $set: { customerName: "Deleted Customer" } },
    );

    // 2. Delete the customer's loyalty card.
    await LoyaltyCard.deleteOne({ customerId: customer._id });

    // 3. Delete the customer document last so we never leave orphaned personal data.
    await Customer.findByIdAndDelete(customer._id);

    return NextResponse.json({ deleted: true });
  } catch (err) {
    return handleApiError(err);
  }
}


