import { NextResponse } from "next/server";
import mongoose from "mongoose";
import { auth } from "@/auth";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";
import { ApiError, handleApiError } from "@/lib/api-error";

interface LoyaltyMeResponse {
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
  stampToken: string;
  redeemToken?: string;
}

// GET /api/loyalty/me (customer session)
// Returns the current customer's loyalty card status and stampToken.
// redeemToken is strictly omitted from the response object unless rewardReady is true.
export async function GET() {
  try {
    const session = await auth();

    if (!session?.user?.id) {
      throw new ApiError(401, "UNAUTHORIZED", "Not signed in.");
    }

    await connectDB();

    if (!mongoose.isValidObjectId(session.user.id)) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    const customer = await Customer.findById(session.user.id).lean();

    if (!customer) {
      throw new ApiError(404, "NOT_FOUND", "Customer not found.");
    }

    const loyaltyCard = await LoyaltyCard.findOne({
      customerId: customer._id,
    }).lean();

    if (!loyaltyCard) {
      throw new ApiError(404, "NOT_FOUND", "Loyalty card not found.");
    }

    const responseBody: LoyaltyMeResponse = {
      stamps: loyaltyCard.stamps,
      totalRequired: loyaltyCard.totalRequired,
      rewardReady: loyaltyCard.rewardReady,
      stampToken: customer.stampToken,
    };

    if (loyaltyCard.rewardReady) {
      responseBody.redeemToken = customer.redeemToken;
    }

    return NextResponse.json(responseBody, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}
