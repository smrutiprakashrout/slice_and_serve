import { beforeEach, describe, expect, it, vi } from "vitest";

const { authMock, connectDBMock, createOrderMock, sendNotificationMock } = vi.hoisted(
  () => ({
    authMock: vi.fn(),
    connectDBMock: vi.fn(async () => undefined),
    createOrderMock: vi.fn(),
    sendNotificationMock: vi.fn(),
  }),
);

vi.mock("@/auth", () => ({ auth: authMock }));
vi.mock("@/lib/db", () => ({ connectDB: connectDBMock }));
vi.mock("@/lib/order-notifications", () => ({
  sendNewOrderNotification: sendNotificationMock,
}));
vi.mock("@/model/Customer", () => ({
  default: { findById: vi.fn() },
}));
vi.mock("@/model/MenuItem", () => ({
  default: { findById: vi.fn() },
}));
vi.mock("@/model/Order", () => ({
  default: { create: createOrderMock },
}));

import Customer from "@/model/Customer";
import MenuItem from "@/model/MenuItem";
import { POST } from "@/app/api/orders/route";

const customerId = "64b000000000000000000001";
const menuItemId = "64b000000000000000000002";
const orderId = "64b000000000000000000003";

function queryWithLean(value: unknown) {
  return { lean: async () => value };
}

function orderRequest() {
  return new Request("http://localhost/api/orders", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      items: [{ menuItemId, quantity: 1 }],
      fulfillment: "pickup",
    }),
  });
}

describe("POST /api/orders notification integration", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    authMock.mockResolvedValue({ user: { id: customerId } });
    vi.mocked(Customer.findById).mockReturnValue(
      queryWithLean({ _id: customerId, name: "Test Admin" }) as never,
    );
    vi.mocked(MenuItem.findById).mockReturnValue(
      queryWithLean({
        _id: menuItemId,
        name: "Test item",
        price: 100,
        available: true,
      }) as never,
    );
    createOrderMock.mockResolvedValue({
      _id: { toString: () => orderId },
      customerId: { toString: () => customerId },
      customerName: "Test Admin",
      fulfillment: "pickup",
      items: [
        {
          _id: { toString: () => "item-1" },
          menuItemId: { toString: () => menuItemId },
          name: "Test item",
          price: 100,
          quantity: 1,
        },
      ],
      itemTotal: 100,
      total: 100,
      status: "pending",
      placedAt: new Date("2026-01-01T00:00:00.000Z"),
      createdAt: new Date("2026-01-01T00:00:00.000Z"),
      updatedAt: new Date("2026-01-01T00:00:00.000Z"),
    });
    sendNotificationMock.mockResolvedValue({
      status: "failed",
      recipientCount: 1,
      successCount: 0,
      failureCount: 1,
      invalidTokensRemoved: 0,
      errorCodes: ["messaging/permission-denied"],
    });
  });

  it("preserves the created order response when FCM sending fails", async () => {
    const response = await POST(orderRequest());

    expect(createOrderMock).toHaveBeenCalledOnce();
    expect(sendNotificationMock).toHaveBeenCalledWith(orderId);
    expect(response.status).toBe(201);
    expect(await response.json()).toMatchObject({ id: orderId, status: "pending" });
  });

  it("preserves the created order response if the sender unexpectedly throws", async () => {
    sendNotificationMock.mockRejectedValueOnce(new Error("FCM request failed"));

    const response = await POST(orderRequest());

    expect(createOrderMock).toHaveBeenCalledOnce();
    expect(response.status).toBe(201);
    expect(await response.json()).toMatchObject({ id: orderId, status: "pending" });
  });

  it("does not attempt a notification when order persistence fails", async () => {
    createOrderMock.mockRejectedValueOnce(new Error("database write failed"));

    const response = await POST(orderRequest());

    expect(sendNotificationMock).not.toHaveBeenCalled();
    expect(response.status).not.toBe(201);
  });
});
