import { ApiError } from "@/lib/api-error";

export interface LoyaltyCardState {
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
}

/**
 * Pure function: increments loyalty card stamps by 1, setting rewardReady = true
 * once stamps reaches totalRequired, and clamping stamps to never exceed totalRequired.
 *
 * Throws ApiError(409, "REWARD_ALREADY_READY", ...) if rewardReady is already true.
 * Does not mutate the input object.
 */
export function applyStamp(card: LoyaltyCardState): LoyaltyCardState {
  if (card.rewardReady) {
    throw new ApiError(
      409,
      "REWARD_ALREADY_READY",
      "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
    );
  }

  const nextStamps = Math.min(card.stamps + 1, card.totalRequired);
  const rewardReady = nextStamps >= card.totalRequired;

  return {
    stamps: nextStamps,
    totalRequired: card.totalRequired,
    rewardReady,
  };
}

/**
 * Pure function: resets stamps to 0 and rewardReady to false for a redeemed card.
 *
 * Throws ApiError(409, "REWARD_NOT_READY", ...) if rewardReady is false.
 * Does not mutate the input object.
 */
export function applyRedeem(card: LoyaltyCardState): LoyaltyCardState {
  if (!card.rewardReady) {
    throw new ApiError(
      409,
      "REWARD_NOT_READY",
      "This customer's card isn't full yet.",
    );
  }

  return {
    stamps: 0,
    totalRequired: card.totalRequired,
    rewardReady: false,
  };
}
