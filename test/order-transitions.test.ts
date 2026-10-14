import { describe, it, expect } from "vitest";
import { assertValidTransition } from "@/lib/order-transitions";
import { ApiError } from "@/lib/api-error";
import type { OrderStatus } from "@/model/Order";

describe("assertValidTransition", () => {
  describe("Valid transitions (must succeed without throwing)", () => {
    it("allows pending → accepted", () => {
      expect(() => assertValidTransition("pending", "accepted")).not.toThrow();
    });

    it("allows pending → rejected", () => {
      expect(() => assertValidTransition("pending", "rejected")).not.toThrow();
    });

    it("allows accepted → completed", () => {
      expect(() => assertValidTransition("accepted", "completed")).not.toThrow();
    });
  });

  describe("Invalid transitions (must throw 409 INVALID_TRANSITION)", () => {
    it("blocks pending → completed (critical guard: skipping accepted)", () => {
      expect(() => assertValidTransition("pending", "completed")).toThrowError(
        ApiError,
      );
      try {
        assertValidTransition("pending", "completed");
      } catch (err: unknown) {
        expect(err).toBeInstanceOf(ApiError);
        const apiErr = err as ApiError;
        expect(apiErr.status).toBe(409);
        expect(apiErr.code).toBe("INVALID_TRANSITION");
        expect(apiErr.message).toBe(
          "Cannot transition an order from pending to completed.",
        );
      }
    });

    it("blocks accepted → rejected", () => {
      expect(() => assertValidTransition("accepted", "rejected")).toThrowError(
        ApiError,
      );
    });

    it("blocks completed → accepted", () => {
      expect(() => assertValidTransition("completed", "accepted")).toThrowError(
        ApiError,
      );
    });

    it("blocks rejected → completed", () => {
      expect(() => assertValidTransition("rejected", "completed")).toThrowError(
        ApiError,
      );
    });

    it("blocks no-op transitions (any status to itself)", () => {
      expect(() => assertValidTransition("pending", "pending")).toThrowError(
        ApiError,
      );
      expect(() => assertValidTransition("accepted", "accepted")).toThrowError(
        ApiError,
      );
      expect(() =>
        assertValidTransition("completed", "completed"),
      ).toThrowError(ApiError);
      expect(() => assertValidTransition("rejected", "rejected")).toThrowError(
        ApiError,
      );
    });

    it("blocks any transition from completed state", () => {
      expect(() => assertValidTransition("completed", "pending")).toThrowError(
        ApiError,
      );
      expect(() => assertValidTransition("completed", "accepted")).toThrowError(
        ApiError,
      );
      expect(() => assertValidTransition("completed", "rejected")).toThrowError(
        ApiError,
      );
    });

    it("blocks any transition from rejected state", () => {
      expect(() => assertValidTransition("rejected", "pending")).toThrowError(
        ApiError,
      );
      expect(() => assertValidTransition("rejected", "accepted")).toThrowError(
        ApiError,
      );
      expect(() =>
        assertValidTransition("rejected", "completed"),
      ).toThrowError(ApiError);
    });

    it("blocks accepted → pending (cannot regress back to pending)", () => {
      expect(() => assertValidTransition("accepted", "pending")).toThrowError(
        ApiError,
      );
    });
  });

  describe("Exhaustive 4x4 transition matrix test", () => {
    const statuses: OrderStatus[] = [
      "pending",
      "accepted",
      "completed",
      "rejected",
    ];

    const validTransitions = new Set<string>([
      "pending->accepted",
      "pending->rejected",
      "accepted->completed",
    ]);

    statuses.forEach((from) => {
      statuses.forEach((to) => {
        const key = `${from}->${to}`;
        if (validTransitions.has(key)) {
          it(`allows valid transition: ${key}`, () => {
            expect(() => assertValidTransition(from, to)).not.toThrow();
          });
        } else {
          it(`rejects invalid transition: ${key}`, () => {
            expect(() => assertValidTransition(from, to)).toThrowError(
              ApiError,
            );
            try {
              assertValidTransition(from, to);
            } catch (err: unknown) {
              expect(err).toBeInstanceOf(ApiError);
              const apiErr = err as ApiError;
              expect(apiErr.status).toBe(409);
              expect(apiErr.code).toBe("INVALID_TRANSITION");
              expect(apiErr.message).toBe(
                `Cannot transition an order from ${from} to ${to}.`,
              );
            }
          });
        }
      });
    });
  });
});
