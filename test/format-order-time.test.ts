import { describe, expect, it } from "vitest";
import { formatOrderTime } from "@/lib/format-order-time";

describe("formatOrderTime", () => {
  const now = new Date(2026, 9, 17, 18, 42);

  it("formats today's order time", () => {
    expect(formatOrderTime(new Date(2026, 9, 17, 18, 42), now)).toBe(
      "Today, 6:42 PM",
    );
  });

  it("formats yesterday's order time", () => {
    expect(formatOrderTime(new Date(2026, 9, 16, 16, 10), now)).toBe(
      "Yesterday, 4:10 PM",
    );
  });

  it("formats older dates with day and short month", () => {
    expect(formatOrderTime(new Date(2026, 9, 12, 16, 10), now)).toBe(
      "12 Oct, 4:10 PM",
    );
  });
});
