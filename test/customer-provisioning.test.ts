import { beforeEach, describe, expect, it, vi } from "vitest";

const { connectDBMock, customerModel, loyaltyModel } = vi.hoisted(() => ({
  connectDBMock: vi.fn(async () => undefined),
  customerModel: {
    findOne: vi.fn(),
    findOneAndUpdate: vi.fn(),
    create: vi.fn(),
  },
  loyaltyModel: { updateOne: vi.fn() },
}));

vi.mock("@/lib/db", () => ({ connectDB: connectDBMock }));
vi.mock("@/model/Customer", () => ({ default: customerModel }));
vi.mock("@/model/LoyaltyCard", () => ({ default: loyaltyModel }));

import { ensureLoyaltyCard, provisionCustomer } from "@/lib/customer-provisioning";

const existingCustomer = (id: string, extra: Record<string, unknown> = {}) => ({
  _id: id,
  ...extra,
});

describe("customer provisioning", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    customerModel.findOne.mockResolvedValue(null);
    customerModel.findOneAndUpdate.mockResolvedValue(null);
    customerModel.create.mockResolvedValue(existingCustomer("64b000000000000000000001"));
    loyaltyModel.updateOne.mockResolvedValue({ acknowledged: true });
  });

  it("returns an existing Google customer without creating and ensures its card", async () => {
    customerModel.findOne.mockResolvedValueOnce(existingCustomer("64b000000000000000000001"));

    await expect(
      provisionCustomer({ googleId: "google-1", email: "USER@example.com" }),
    ).resolves.toEqual({ id: "64b000000000000000000001" });
    expect(customerModel.create).not.toHaveBeenCalled();
    expect(loyaltyModel.updateOne).toHaveBeenCalledWith(
      { customerId: "64b000000000000000000001" },
      { $setOnInsert: { customerId: "64b000000000000000000001", stamps: 0, totalRequired: 10, rewardReady: false } },
      { upsert: true },
    );
  });

  it("adopts a matching verified email without creating", async () => {
    const prior = existingCustomer("64b000000000000000000002");
    customerModel.findOne.mockResolvedValueOnce(null).mockResolvedValueOnce(prior);
    customerModel.findOneAndUpdate.mockResolvedValue(prior);

    await expect(
      provisionCustomer({ googleId: "google-2", email: " User@Example.com ", emailVerified: true }),
    ).resolves.toEqual({ id: "64b000000000000000000002" });
    expect(customerModel.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: prior._id },
      { $set: { googleId: "google-2" } },
      { new: true, runValidators: true },
    );
    expect(customerModel.create).not.toHaveBeenCalled();
  });

  it("does not adopt a matching email when it is explicitly unverified", async () => {
    customerModel.findOne.mockResolvedValueOnce(null).mockResolvedValueOnce(existingCustomer("64b000000000000000000003"));

    await expect(
      provisionCustomer({ googleId: "google-3", email: "user@example.com", emailVerified: false }),
    ).rejects.toThrow("Cannot link an unverified email");
    expect(customerModel.findOneAndUpdate).not.toHaveBeenCalled();
    expect(customerModel.create).not.toHaveBeenCalled();
  });

  it("creates a new customer with fresh tokens and ensures a card", async () => {
    const created = existingCustomer("64b000000000000000000004");
    customerModel.create.mockResolvedValue(created);

    await expect(
      provisionCustomer({ googleId: "google-4", email: " NEW@Example.com ", name: "  ", photo: null }),
    ).resolves.toEqual({ id: created._id });
    const payload = customerModel.create.mock.calls[0][0];
    expect(payload).toMatchObject({ googleId: "google-4", name: "Customer", email: "new@example.com" });
    expect(payload.stampToken).toEqual(expect.any(String));
    expect(payload.redeemToken).toEqual(expect.any(String));
    expect(payload.stampToken).not.toBe(payload.redeemToken);
    expect(loyaltyModel.updateOne).toHaveBeenCalledOnce();
  });

  it("re-reads and returns the customer created by a duplicate-key race", async () => {
    const raced = existingCustomer("64b000000000000000000005");
    customerModel.create.mockRejectedValueOnce(Object.assign(new Error("duplicate"), { code: 11000 }));
    customerModel.findOne
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(raced);

    await expect(
      provisionCustomer({ googleId: "google-5", email: "race@example.com" }),
    ).resolves.toEqual({ id: raced._id });
    expect(customerModel.create).toHaveBeenCalledOnce();
    expect(loyaltyModel.updateOne).toHaveBeenCalledOnce();
  });

  it("rejects a missing email", async () => {
    await expect(provisionCustomer({ googleId: "google-6", email: "  " })).rejects.toThrow(
      "A non-empty Google account email is required",
    );
    expect(connectDBMock).not.toHaveBeenCalled();
  });

  it("creates a missing loyalty card for an existing customer", async () => {
    customerModel.findOne.mockResolvedValueOnce(existingCustomer("64b000000000000000000007"));

    await provisionCustomer({ googleId: "google-7", email: "card@example.com" });

    expect(loyaltyModel.updateOne).toHaveBeenCalledOnce();
    await expect(ensureLoyaltyCard("64b000000000000000000007")).resolves.toBeUndefined();
  });

  it("creates a fresh customer when a deleted account signs in again", async () => {
    let nextId = 0;
    customerModel.create
      .mockResolvedValueOnce(existingCustomer("64b000000000000000000008"))
      .mockImplementationOnce(async () => existingCustomer(`64b00000000000000000000${++nextId}9`));

    const first = await provisionCustomer({ googleId: "google-8", email: "deleted@example.com" });
    customerModel.findOne.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
    const second = await provisionCustomer({ googleId: "google-8", email: "deleted@example.com" });

    expect(first.id).not.toBe(second.id);
    expect(customerModel.create).toHaveBeenCalledTimes(2);
  });
});
