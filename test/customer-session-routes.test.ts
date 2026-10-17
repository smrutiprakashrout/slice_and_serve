import { beforeEach, describe, expect, it, vi } from "vitest";

const { authMock, connectDBMock, customerModel, loyaltyModel, orderModel, ensureCardMock } =
  vi.hoisted(() => ({
    authMock: vi.fn(),
    connectDBMock: vi.fn(async () => undefined),
    customerModel: { findById: vi.fn() },
    loyaltyModel: { updateOne: vi.fn(), findOne: vi.fn() },
    orderModel: { updateMany: vi.fn(), findByIdAndDelete: vi.fn() },
    ensureCardMock: vi.fn(async (customerId: string) =>
      loyaltyModel.updateOne(
        { customerId },
        { $setOnInsert: { customerId, stamps: 0, totalRequired: 10, rewardReady: false } },
        { upsert: true },
      ),
    ),
  }));

vi.mock("@/auth", () => ({ auth: authMock }));
vi.mock("@/lib/db", () => ({ connectDB: connectDBMock }));
vi.mock("@/model/Customer", () => ({ default: customerModel }));
vi.mock("@/model/LoyaltyCard", () => ({ default: loyaltyModel }));
vi.mock("@/model/Order", () => ({ default: orderModel }));
vi.mock("@/lib/customer-provisioning", () => ({ ensureLoyaltyCard: ensureCardMock }));

import { GET as getMe, DELETE as deleteMe } from "@/app/api/me/route";
import { GET as getLoyalty } from "@/app/api/loyalty/me/route";

const validId = "64b000000000000000000001";

describe("customer-session routes", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    authMock.mockResolvedValue({ user: { id: validId } });
    customerModel.findById.mockReturnValue({ lean: async () => null });
    loyaltyModel.updateOne.mockResolvedValue({ acknowledged: true });
    loyaltyModel.findOne.mockReturnValue({
      lean: async () => ({ stamps: 0, totalRequired: 10, rewardReady: false }),
    });
  });

  it("returns 401 SESSION_INVALID for an invalid customer id", async () => {
    authMock.mockResolvedValueOnce({ user: { id: "not-an-object-id" } });
    const response = await getMe();

    expect(response.status).toBe(401);
    expect(await response.json()).toMatchObject({ error: { code: "SESSION_INVALID" } });
  });

  it("returns 401 SESSION_INVALID when the customer record is gone", async () => {
    const response = await getMe();

    expect(response.status).toBe(401);
    expect(await response.json()).toMatchObject({ error: { code: "SESSION_INVALID" } });
  });

  it("makes DELETE idempotent when the customer is already gone", async () => {
    customerModel.findById.mockResolvedValueOnce(null);
    const response = await deleteMe();

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ deleted: true });
    expect(orderModel.updateMany).not.toHaveBeenCalled();
  });

  it("does not write when the loyalty card already exists", async () => {
    customerModel.findById.mockReturnValue({
      lean: async () => ({ _id: validId, stampToken: "stamp-token", redeemToken: "redeem-token" }),
    });
    loyaltyModel.findOne.mockReturnValue({
      lean: async () => ({ stamps: 0, totalRequired: 10, rewardReady: false }),
    });

    const response = await getLoyalty();

    expect(response.status).toBe(200);
    expect(ensureCardMock).not.toHaveBeenCalled();
    expect(loyaltyModel.updateOne).not.toHaveBeenCalled();
    expect(await response.json()).toEqual({
      stamps: 0,
      totalRequired: 10,
      rewardReady: false,
      stampToken: "stamp-token",
    });
  });

  it("creates a missing loyalty card once and returns the usual response", async () => {
    customerModel.findById.mockReturnValue({
      lean: async () => ({ _id: validId, stampToken: "stamp-token", redeemToken: "redeem-token" }),
    });
    loyaltyModel.findOne
      .mockReturnValueOnce({ lean: async () => null })
      .mockReturnValueOnce({
        lean: async () => ({ stamps: 0, totalRequired: 10, rewardReady: false }),
      });

    const response = await getLoyalty();

    expect(response.status).toBe(200);
    expect(ensureCardMock).toHaveBeenCalledOnce();
    expect(ensureCardMock).toHaveBeenCalledWith(validId);
    expect(loyaltyModel.updateOne).toHaveBeenCalledOnce();
    expect(await response.json()).toEqual({
      stamps: 0,
      totalRequired: 10,
      rewardReady: false,
      stampToken: "stamp-token",
    });
  });
});
