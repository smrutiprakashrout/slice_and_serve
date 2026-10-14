import { describe, it, expect } from "vitest";
import {
  applyStamp,
  applyRedeem,
  type LoyaltyCardState,
} from "@/lib/loyalty-actions";
import { ApiError } from "@/lib/api-error";

describe("Loyalty Actions (Pure Functions)", () => {
  describe("applyStamp", () => {
    it("increments by exactly 1 and keeps rewardReady false when stamps < totalRequired - 1", () => {
      const card: LoyaltyCardState = {
        stamps: 3,
        totalRequired: 10,
        rewardReady: false,
      };

      const result = applyStamp(card);

      expect(result).toEqual({
        stamps: 4,
        totalRequired: 10,
        rewardReady: false,
      });
    });

    it("increments to totalRequired and flips rewardReady to true when stamps === totalRequired - 1", () => {
      const card: LoyaltyCardState = {
        stamps: 9,
        totalRequired: 10,
        rewardReady: false,
      };

      const result = applyStamp(card);

      expect(result).toEqual({
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
      });
    });

    it("throws 409 REWARD_ALREADY_READY when card already has rewardReady: true and does not mutate input", () => {
      const card: LoyaltyCardState = {
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
      };

      expect(() => applyStamp(card)).toThrowError(ApiError);

      try {
        applyStamp(card);
      } catch (err: unknown) {
        expect(err).toBeInstanceOf(ApiError);
        const apiErr = err as ApiError;
        expect(apiErr.status).toBe(409);
        expect(apiErr.code).toBe("REWARD_ALREADY_READY");
        expect(apiErr.message).toBe(
          "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
        );
      }

      // Assert input was not mutated
      expect(card).toEqual({
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
      });
    });

    it("never produces stamps > totalRequired under any input constructed", () => {
      // Input already at totalRequired with rewardReady: false
      const atCap: LoyaltyCardState = {
        stamps: 10,
        totalRequired: 10,
        rewardReady: false,
      };
      const res1 = applyStamp(atCap);
      expect(res1.stamps).toBe(10);
      expect(res1.stamps).toBeLessThanOrEqual(res1.totalRequired);

      // Input beyond totalRequired
      const overCap: LoyaltyCardState = {
        stamps: 15,
        totalRequired: 10,
        rewardReady: false,
      };
      const res2 = applyStamp(overCap);
      expect(res2.stamps).toBe(10);
      expect(res2.stamps).toBeLessThanOrEqual(res2.totalRequired);

      // Non-standard totalRequired (e.g. 5)
      const customCap: LoyaltyCardState = {
        stamps: 4,
        totalRequired: 5,
        rewardReady: false,
      };
      const res3 = applyStamp(customCap);
      expect(res3.stamps).toBe(5);
      expect(res3.rewardReady).toBe(true);
      expect(res3.stamps).toBeLessThanOrEqual(res3.totalRequired);
    });

    it("does not mutate the input object and returns a brand new object", () => {
      const originalCard: LoyaltyCardState = Object.freeze({
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
      });

      const result = applyStamp(originalCard);

      expect(result).not.toBe(originalCard);
      expect(originalCard.stamps).toBe(5);
      expect(originalCard.rewardReady).toBe(false);
      expect(result.stamps).toBe(6);
    });
  });

  describe("applyRedeem", () => {
    it("resets stamps to 0 and rewardReady to false when rewardReady: true", () => {
      const card: LoyaltyCardState = {
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
      };

      const result = applyRedeem(card);

      expect(result).toEqual({
        stamps: 0,
        totalRequired: 10,
        rewardReady: false,
      });
    });

    it("throws 409 REWARD_NOT_READY when rewardReady is false and does not mutate input", () => {
      const card: LoyaltyCardState = {
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
      };

      expect(() => applyRedeem(card)).toThrowError(ApiError);

      try {
        applyRedeem(card);
      } catch (err: unknown) {
        expect(err).toBeInstanceOf(ApiError);
        const apiErr = err as ApiError;
        expect(apiErr.status).toBe(409);
        expect(apiErr.code).toBe("REWARD_NOT_READY");
        expect(apiErr.message).toBe("This customer's card isn't full yet.");
      }

      // Assert input was not mutated
      expect(card).toEqual({
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
      });
    });

    it("does not mutate the input object and returns a brand new object", () => {
      const originalCard: LoyaltyCardState = Object.freeze({
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
      });

      const result = applyRedeem(originalCard);

      expect(result).not.toBe(originalCard);
      expect(originalCard.stamps).toBe(10);
      expect(originalCard.rewardReady).toBe(true);
      expect(result.stamps).toBe(0);
      expect(result.rewardReady).toBe(false);
    });
  });
});
