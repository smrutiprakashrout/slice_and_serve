import { ApiError } from "@/lib/api-error";
import type { OrderStatus } from "@/model/Order";

/**
 * Valid order transitions:
 *   pending -> accepted
 *   pending -> rejected
 *   accepted -> completed
 *
 * All other transitions throw ApiError(409, "INVALID_TRANSITION", ...).
 */
export function assertValidTransition(
  from: OrderStatus,
  to: OrderStatus,
): void {
  const isValid =
    (from === "pending" && (to === "accepted" || to === "rejected")) ||
    (from === "accepted" && to === "completed");

  if (!isValid) {
    throw new ApiError(
      409,
      "INVALID_TRANSITION",
      `Cannot transition an order from ${from} to ${to}.`,
    );
  }
}
