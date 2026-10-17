import { describe, expect, it } from "vitest";
import {
  computeOrderStats,
  formatMemberSince,
  formatStampProgress,
} from "@/lib/profile-stats";

describe("profile stats", () => {
  it("counts all non-rejected orders and pending or accepted orders in progress", () => {
    expect(computeOrderStats([
      { status: "pending" },
      { status: "accepted" },
      { status: "completed" },
      { status: "rejected" },
      { status: "cancelled" },
    ])).toEqual({ totalOrders: 3, inProgressOrders: 2 });
  });

  it("returns zero counts when orders are unavailable", () => {
    expect(computeOrderStats(undefined)).toEqual({
      totalOrders: 0,
      inProgressOrders: 0,
    });
  });

  it("formats a valid member date in the en-IN month and year format", () => {
    expect(formatMemberSince("2024-05-20T00:00:00.000Z")).toBe("May 2024");
  });

  it("hides missing or invalid member dates", () => {
    expect(formatMemberSince(undefined)).toBeNull();
    expect(formatMemberSince("not-a-date")).toBeNull();
  });

  it("formats the loyalty stamp subtext", () => {
    expect(formatStampProgress(3, 10)).toBe("3 of 10 stamps collected");
  });
});
