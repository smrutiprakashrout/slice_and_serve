import { NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import jwt, { SignOptions } from "jsonwebtoken";
import { connectDB } from "@/lib/db";
import Admin from "@/model/Admin";
import {
  getClientIp,
  isRateLimited,
  recordFailedAttempt,
  resetRateLimit,
} from "@/lib/rate-limit";
import { ApiError, handleApiError } from "@/lib/api-error";

export async function POST(request: Request) {
  try {
    const clientIp = getClientIp(request);
    const { limited } = isRateLimited(clientIp);

    if (limited) {
      throw new ApiError(
        429,
        "RATE_LIMITED",
        "Too many attempts. Try again later.",
      );
    }

    const body = await request.json().catch(() => null);

    if (!body || typeof body !== "object") {
      throw new ApiError(400, "BAD_REQUEST", "Invalid request payload.");
    }

    const { username, password } = body as {
      username?: unknown;
      password?: unknown;
    };

    if (
      !username ||
      !password ||
      typeof username !== "string" ||
      typeof password !== "string"
    ) {
      recordFailedAttempt(clientIp);
      throw new ApiError(401, "INVALID_CREDENTIALS", "Invalid credentials.");
    }

    await connectDB();

    const admin = await Admin.findOne({ username });
    if (!admin) {
      recordFailedAttempt(clientIp);
      throw new ApiError(401, "INVALID_CREDENTIALS", "Invalid credentials.");
    }

    const isMatch = await bcrypt.compare(password, admin.passwordHash);
    if (!isMatch) {
      recordFailedAttempt(clientIp);
      throw new ApiError(401, "INVALID_CREDENTIALS", "Invalid credentials.");
    }

    // Reset rate-limit counter for this IP upon successful authentication
    resetRateLimit(clientIp);

    const secret = process.env.ADMIN_JWT_SECRET;
    if (!secret) {
      throw new ApiError(
        500,
        "INTERNAL_ERROR",
        "ADMIN_JWT_SECRET environment variable is missing.",
      );
    }

    const expiresIn =
      (process.env.ADMIN_JWT_EXPIRY as SignOptions["expiresIn"]) || "24h";

    const token = jwt.sign(
      {
        id: admin._id.toString(),
        username: admin.username,
      },
      secret,
      { expiresIn },
    );

    return NextResponse.json({ token }, { status: 200 });
  } catch (err) {
    return handleApiError(err);
  }
}
