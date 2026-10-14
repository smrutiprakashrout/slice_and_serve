import jwt from "jsonwebtoken";
import { ApiError } from "@/lib/api-error";

export interface AdminPayload {
  id: string;
  username: string;
  iat?: number;
  exp?: number;
}

/**
 * Verifies the admin Authorization Bearer JWT token from the incoming Request.
 * Throws ApiError (status 401) if missing, malformed, invalid, or expired.
 * Does not touch the database.
 */
export async function requireAdmin(request: Request): Promise<AdminPayload> {
  const authHeader =
    request.headers.get("authorization") ||
    request.headers.get("Authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new ApiError(401, "UNAUTHORIZED", "Unauthorized");
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    throw new ApiError(401, "UNAUTHORIZED", "Unauthorized");
  }

  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) {
    throw new ApiError(
      500,
      "INTERNAL_ERROR",
      "ADMIN_JWT_SECRET environment variable is missing",
    );
  }

  try {
    const decoded = jwt.verify(token, secret);
    if (
      !decoded ||
      typeof decoded !== "object" ||
      !("id" in decoded) ||
      !("username" in decoded)
    ) {
      throw new ApiError(401, "UNAUTHORIZED", "Unauthorized");
    }

    return decoded as AdminPayload;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new ApiError(401, "UNAUTHORIZED", "Unauthorized");
  }
}

export default requireAdmin;
