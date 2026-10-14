import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";
import { applyStamp } from "@/lib/loyalty-actions";

interface RouteContext {
  params: Promise<{ customerId: string }>;
}

interface StampResponse {
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
}

// POST /api/loyalty/:customerId/stamp (admin only)
// Increments loyalty card stamps by 1, setting rewardReady when reaching totalRequired.
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

    const updatedCard = applyStamp({
      stamps: loyaltyCard.stamps,
      totalRequired: loyaltyCard.totalRequired,
      rewardReady: loyaltyCard.rewardReady,
    });

    loyaltyCard.stamps = updatedCard.stamps;
    loyaltyCard.rewardReady = updatedCard.rewardReady;
    await loyaltyCard.save();

    const responseBody: StampResponse = {
      stamps: loyaltyCard.stamps,
      totalRequired: loyaltyCard.totalRequired,
      rewardReady: loyaltyCard.rewardReady,
    };

    return NextResponse.json(responseBody, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}
