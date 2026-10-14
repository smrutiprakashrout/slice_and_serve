import { NextResponse } from "next/server";
import mongoose from "mongoose";
import crypto from "node:crypto";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";
import { applyRedeem } from "@/lib/loyalty-actions";

interface RouteContext {
  params: Promise<{ customerId: string }>;
}

interface RedeemResponse {
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
}

// POST /api/loyalty/:customerId/redeem (admin only)
// Redeems a full loyalty card, resets stamps to 0, and rotates the customer's redeemToken.
export async function POST(request: Request, context: RouteContext) {
  try {
    await requireAdmin(request);
    await connectDB();

    const { customerId } = await context.params;

    if (!customerId || !mongoose.isValidObjectId(customerId)) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    const customer = await Customer.findById(customerId);

    if (!customer) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    const loyaltyCard = await LoyaltyCard.findOne({
      customerId: customer._id,
    });

    if (!loyaltyCard) {
      throw new ApiError(404, "NOT_FOUND", "Loyalty card not found.");
    }

    const updatedCard = applyRedeem({
      stamps: loyaltyCard.stamps,
      totalRequired: loyaltyCard.totalRequired,
      rewardReady: loyaltyCard.rewardReady,
    });

    // Reset card values
    loyaltyCard.stamps = updatedCard.stamps;
    loyaltyCard.rewardReady = updatedCard.rewardReady;

    // Rotate redeem token to invalidate any previous screenshots/scans
    customer.redeemToken = crypto.randomUUID();

    // Two-document persistence:
    // A full multi-document transaction is not required at this project scale,
    // but we persist customer first and explicitly log if the loyalty card reset fails
    // so any failure window is immediately visible and debuggable.
    await customer.save();
    try {
      await loyaltyCard.save();
    } catch (cardSaveErr) {
      console.error(
        `CRITICAL: Customer ${customer._id} redeemToken was rotated, but LoyaltyCard save failed:`,
        cardSaveErr,
      );
      throw cardSaveErr;
    }

    const responseBody: RedeemResponse = {
      stamps: loyaltyCard.stamps,
      totalRequired: loyaltyCard.totalRequired,
      rewardReady: loyaltyCard.rewardReady,
    };

    return NextResponse.json(responseBody, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}
