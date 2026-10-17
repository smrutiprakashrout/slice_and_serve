import crypto from "node:crypto";
import type { Types } from "mongoose";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";

export interface ProvisionCustomerInput {
  googleId: string;
  email: string | null | undefined;
  emailVerified?: boolean;
  name?: string | null;
  photo?: string | null;
}

function isDuplicateKeyError(error: unknown): error is { code: number } {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === 11000
  );
}

function emailLookup(email: string): RegExp {
  const escaped = email.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`^${escaped}$`, "i");
}

function customerId(customer: { _id: Types.ObjectId | string }): string {
  return customer._id.toString();
}

async function findByGoogleId(googleId: string) {
  return Customer.findOne({ googleId });
}

async function findByEmail(email: string) {
  return Customer.findOne({ email: emailLookup(email) });
}

export async function ensureLoyaltyCard(
  id: Types.ObjectId | string,
): Promise<void> {
  try {
    await LoyaltyCard.updateOne(
      { customerId: id },
      {
        $setOnInsert: {
          customerId: id,
          stamps: 0,
          totalRequired: 10,
          rewardReady: false,
        },
      },
      { upsert: true },
    );
  } catch (error) {
    if (!isDuplicateKeyError(error)) throw error;
  }
}

export async function provisionCustomer(
  input: ProvisionCustomerInput,
): Promise<{ id: string }> {
  const googleId = input.googleId.trim();
  const email = input.email?.trim().toLowerCase() ?? "";

  if (!googleId) throw new Error("Google account id is required.");
  if (!email) throw new Error("A non-empty Google account email is required.");

  await connectDB();

  const existingByGoogleId = await findByGoogleId(googleId);
  if (existingByGoogleId) {
    await ensureLoyaltyCard(existingByGoogleId._id);
    return { id: customerId(existingByGoogleId) };
  }

  const existingByEmail = await findByEmail(email);
  if (existingByEmail) {
    if (input.emailVerified === false) {
      throw new Error("Cannot link an unverified email to an existing customer.");
    }

    try {
      const adopted = await Customer.findOneAndUpdate(
        { _id: existingByEmail._id },
        { $set: { googleId } },
        { new: true, runValidators: true },
      );
      if (!adopted) {
        const racedCustomer = await findByGoogleId(googleId);
        if (!racedCustomer) {
          throw new Error("Customer account could not be linked after a concurrent update.");
        }
        await ensureLoyaltyCard(racedCustomer._id);
        return { id: customerId(racedCustomer) };
      }

      await ensureLoyaltyCard(adopted._id);
      return { id: customerId(adopted) };
    } catch (error) {
      if (!isDuplicateKeyError(error)) throw error;
      const racedCustomer = await findByGoogleId(googleId);
      if (!racedCustomer) throw error;
      await ensureLoyaltyCard(racedCustomer._id);
      return { id: customerId(racedCustomer) };
    }
  }

  let lastDuplicateError: unknown;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const created = await Customer.create({
        googleId,
        name: input.name?.trim() || "Customer",
        email,
        ...(input.photo ? { photo: input.photo } : {}),
        stampToken: crypto.randomUUID(),
        redeemToken: crypto.randomUUID(),
      });
      await ensureLoyaltyCard(created._id);
      return { id: customerId(created) };
    } catch (error) {
      if (!isDuplicateKeyError(error)) throw error;
      lastDuplicateError = error;

      const racedCustomer = await findByGoogleId(googleId);
      if (racedCustomer) {
        await ensureLoyaltyCard(racedCustomer._id);
        return { id: customerId(racedCustomer) };
      }

      if (input.emailVerified !== false) {
        const customerWithEmail = await findByEmail(email);
        if (customerWithEmail) {
          await ensureLoyaltyCard(customerWithEmail._id);
          return { id: customerId(customerWithEmail) };
        }
      }
    }
  }

  throw lastDuplicateError instanceof Error
    ? lastDuplicateError
    : new Error("Customer could not be provisioned after concurrent updates.");
}
