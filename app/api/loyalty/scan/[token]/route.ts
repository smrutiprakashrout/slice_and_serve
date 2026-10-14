import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";
import { requireAdmin } from "@/lib/admin-auth";
import { ApiError, handleApiError } from "@/lib/api-error";

interface RouteContext {
  params: Promise<{ token: string }>;
}

interface ScanResponse {
  customer: {
    id: string;
    name: string;
  };
  card: {
    stamps: number;
    totalRequired: number;
    rewardReady: boolean;
  };
  action: "stamp" | "redeem";
}

// GET /api/loyalty/scan/:token (admin only)
// Resolves a scanned QR token to a customer and loyalty card,
// determining whether the action is "stamp" or "redeem".
export async function GET(request: Request, context: RouteContext) {
  try {
    await requireAdmin(request);
    await connectDB();

    const { token } = await context.params;

    if (!token) {
      throw new ApiError(
        404,
        "TOKEN_NOT_FOUND",
        "This QR code doesn't match any customer.",
      );
    }

    const customer = await Customer.findOne({
      $or: [{ stampToken: token }, { redeemToken: token }],
    }).lean();

    if (!customer) {
      throw new ApiError(
        404,
        "TOKEN_NOT_FOUND",
        "This QR code doesn't match any customer.",
      );
    }

    const action: "stamp" | "redeem" =
      customer.stampToken === token ? "stamp" : "redeem";

    const loyaltyCard = await LoyaltyCard.findOne({
      customerId: customer._id,
    }).lean();

    if (!loyaltyCard) {
      throw new ApiError(404, "NOT_FOUND", "Loyalty card not found.");
    }

    const responseBody: ScanResponse = {
      customer: {
        id: customer._id.toString(),
        name: customer.name,
      },
      card: {
        stamps: loyaltyCard.stamps,
        totalRequired: loyaltyCard.totalRequired,
        rewardReady: loyaltyCard.rewardReady,
      },
      action,
    };

    return NextResponse.json(responseBody, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}
