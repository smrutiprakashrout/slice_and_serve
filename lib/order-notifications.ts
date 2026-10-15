import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { connectDB } from "@/lib/db";
import Admin from "@/model/Admin";

const ANDROID_ORDER_CHANNEL_ID = "sns_new_orders";
const FCM_MULTICAST_LIMIT = 500;

export type OrderNotificationResult =
  | { status: "no_recipients"; recipientCount: 0 }
  | {
      status: "sent" | "partial" | "failed";
      recipientCount: number;
      successCount: number;
      failureCount: number;
      invalidTokensRemoved: number;
      errorCodes?: string[];
    };

class NotificationConfigurationError extends Error {
  readonly code = "notification/configuration_missing";
}

function firebaseMessaging() {
  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n").trim();

  if (!projectId || !clientEmail || !privateKey) {
    throw new NotificationConfigurationError();
  }

  const existingApp = getApps().find((app) => app.name === "[DEFAULT]");
  const app = existingApp ?? initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
    projectId,
  });

  return getMessaging(app);
}

function safeErrorCode(error: unknown): string {
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = (error as { code?: unknown }).code;
    if (typeof code === "string" && /^[A-Za-z0-9/_-]{1,80}$/.test(code)) {
      return code;
    }
  }
  return "unknown";
}

function isStaleTokenError(code: string): boolean {
  return (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  );
}

async function removeStaleToken(token: string): Promise<boolean> {
  try {
    const result = await Admin.updateMany(
      { fcmTokens: token },
      { $pull: { fcmTokens: token } },
    );
    return result.modifiedCount > 0;
  } catch {
    // A token cleanup failure must not hide the FCM send result.
    return false;
  }
}

/** Sends an order notification to every token registered by an authenticated admin. */
export async function sendNewOrderNotification(
  orderId: string,
): Promise<OrderNotificationResult> {
  let tokens: string[];
  try {
    await connectDB();
    const admins = await Admin.find({ fcmTokens: { $exists: true, $ne: [] } })
      .select({ fcmTokens: 1 })
      .lean();
    tokens = [
      ...new Set(
        admins.flatMap((admin) =>
          Array.isArray(admin.fcmTokens)
            ? admin.fcmTokens.filter((token) => typeof token === "string" && token.trim())
            : [],
        ),
      ),
    ];
  } catch (error) {
    return {
      status: "failed",
      recipientCount: 0,
      successCount: 0,
      failureCount: 0,
      invalidTokensRemoved: 0,
      errorCodes: [`notification/token_lookup_${safeErrorCode(error)}`],
    };
  }

  if (tokens.length === 0) {
    return { status: "no_recipients", recipientCount: 0 };
  }

  let messaging: ReturnType<typeof getMessaging>;
  try {
    messaging = firebaseMessaging();
  } catch (error) {
    return {
      status: "failed",
      recipientCount: tokens.length,
      successCount: 0,
      failureCount: tokens.length,
      invalidTokensRemoved: 0,
      errorCodes: [safeErrorCode(error)],
    };
  }

  const shortOrderId = orderId.slice(-6).toUpperCase();
  const title = "New customer order";
  const body = `A new order (#${shortOrderId}) has been placed.`;
  let successCount = 0;
  let failureCount = 0;
  let invalidTokensRemoved = 0;
  const errorCodes = new Set<string>();

  for (let offset = 0; offset < tokens.length; offset += FCM_MULTICAST_LIMIT) {
    const batch = tokens.slice(offset, offset + FCM_MULTICAST_LIMIT);
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: {
          type: "order_new",
          orderId,
          title,
          body,
        },
        android: {
          priority: "high",
          notification: { channelId: ANDROID_ORDER_CHANNEL_ID },
        },
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      for (let index = 0; index < response.responses.length; index += 1) {
        const sendResponse = response.responses[index];
        if (sendResponse.success) continue;

        const code = safeErrorCode(sendResponse.error);
        errorCodes.add(code);
        if (isStaleTokenError(code) && await removeStaleToken(batch[index])) {
          invalidTokensRemoved += 1;
        }
      }
    } catch (error) {
      failureCount += batch.length;
      errorCodes.add(safeErrorCode(error));
    }
  }

  return {
    status:
      successCount === 0
        ? "failed"
        : failureCount > 0
          ? "partial"
          : "sent",
    recipientCount: tokens.length,
    successCount,
    failureCount,
    invalidTokensRemoved,
    ...(errorCodes.size > 0 ? { errorCodes: [...errorCodes] } : {}),
  };
}
