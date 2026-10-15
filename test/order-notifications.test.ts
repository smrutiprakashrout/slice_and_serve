import { beforeEach, describe, expect, it, vi } from "vitest";

const {
  certMock,
  getAppsMock,
  getMessagingMock,
  initializeAppMock,
  sendEachForMulticastMock,
  connectDBMock,
} = vi.hoisted(() => ({
  certMock: vi.fn((serviceAccount: unknown) => serviceAccount),
  getAppsMock: vi.fn(() => [] as Array<{ name: string }>),
  getMessagingMock: vi.fn(),
  initializeAppMock: vi.fn(() => ({ name: "[DEFAULT]" })),
  sendEachForMulticastMock: vi.fn(),
  connectDBMock: vi.fn(async () => undefined),
}));

vi.mock("firebase-admin/app", () => ({
  cert: certMock,
  getApps: getAppsMock,
  initializeApp: initializeAppMock,
}));

vi.mock("firebase-admin/messaging", () => ({
  getMessaging: getMessagingMock,
}));

vi.mock("@/lib/db", () => ({ connectDB: connectDBMock }));

vi.mock("@/model/Admin", () => ({
  default: {
    find: vi.fn(),
    updateMany: vi.fn(),
  },
}));

import Admin from "@/model/Admin";
import { sendNewOrderNotification } from "@/lib/order-notifications";

function setAdmins(admins: Array<{ fcmTokens: string[] }>) {
  vi.mocked(Admin.find).mockReturnValue({
    select: () => ({ lean: async () => admins }),
  } as never);
}

describe("sendNewOrderNotification", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("FIREBASE_PROJECT_ID", "slice-serve-test");
    vi.stubEnv("FIREBASE_CLIENT_EMAIL", "sender@example.test");
    vi.stubEnv("FIREBASE_PRIVATE_KEY", "test-private-key\\nline-two");
    getAppsMock.mockReturnValue([]);
    getMessagingMock.mockReturnValue({ sendEachForMulticast: sendEachForMulticastMock });
    vi.mocked(Admin.updateMany).mockResolvedValue({ modifiedCount: 1 } as never);
    setAdmins([]);
  });

  it("returns no_recipients without initializing Firebase", async () => {
    const result = await sendNewOrderNotification("order-123456");

    expect(result).toEqual({ status: "no_recipients", recipientCount: 0 });
    expect(initializeAppMock).not.toHaveBeenCalled();
    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
  });

  it("fails safely when Firebase credentials are incomplete", async () => {
    setAdmins([{ fcmTokens: ["device-token"] }]);
    vi.stubEnv("FIREBASE_PRIVATE_KEY", "");

    const result = await sendNewOrderNotification("order-123456");

    expect(result).toMatchObject({
      status: "failed",
      recipientCount: 1,
      errorCodes: ["notification/configuration_missing"],
    });
    expect(JSON.stringify(result)).not.toContain("test-private-key");
    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
  });

  it("sends the expected message and removes only an invalid registration token", async () => {
    setAdmins([{ fcmTokens: ["healthy-token", "stale-token", "healthy-token"] }]);
    sendEachForMulticastMock.mockResolvedValue({
      successCount: 1,
      failureCount: 1,
      responses: [
        { success: true },
        {
          success: false,
          error: { code: "messaging/registration-token-not-registered" },
        },
      ],
    });

    const result = await sendNewOrderNotification("0123456789abcdef12345678");

    expect(result).toMatchObject({
      status: "partial",
      recipientCount: 2,
      successCount: 1,
      failureCount: 1,
      invalidTokensRemoved: 1,
    });
    expect(certMock).toHaveBeenCalledWith({
      projectId: "slice-serve-test",
      clientEmail: "sender@example.test",
      privateKey: "test-private-key\nline-two",
    });
    expect(sendEachForMulticastMock).toHaveBeenCalledWith({
      tokens: ["healthy-token", "stale-token"],
      notification: {
        title: "New customer order",
        body: "A new order (#345678) has been placed.",
      },
      data: {
        type: "order_new",
        orderId: "0123456789abcdef12345678",
        title: "New customer order",
        body: "A new order (#345678) has been placed.",
      },
      android: {
        priority: "high",
        notification: { channelId: "sns_new_orders" },
      },
    });
    expect(Admin.updateMany).toHaveBeenCalledWith(
      { fcmTokens: "stale-token" },
      { $pull: { fcmTokens: "stale-token" } },
    );
    expect(JSON.stringify(result)).not.toContain("healthy-token");
    expect(JSON.stringify(result)).not.toContain("stale-token");
  });

  it("does not remove tokens for permission or transient send errors", async () => {
    setAdmins([{ fcmTokens: ["device-token"] }]);
    sendEachForMulticastMock.mockResolvedValue({
      successCount: 0,
      failureCount: 1,
      responses: [
        { success: false, error: { code: "messaging/permission-denied" } },
      ],
    });

    const result = await sendNewOrderNotification("order-123456");

    expect(result).toMatchObject({
      status: "failed",
      failureCount: 1,
      errorCodes: ["messaging/permission-denied"],
    });
    expect(Admin.updateMany).not.toHaveBeenCalled();
  });

  it("reuses an already initialized Firebase app", async () => {
    setAdmins([{ fcmTokens: ["device-token"] }]);
    getAppsMock.mockReturnValue([{ name: "[DEFAULT]" }]);
    sendEachForMulticastMock.mockResolvedValue({
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true }],
    });

    const result = await sendNewOrderNotification("order-123456");

    expect(result.status).toBe("sent");
    expect(initializeAppMock).not.toHaveBeenCalled();
  });
});
