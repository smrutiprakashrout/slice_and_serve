import NextAuth from "next-auth";
import crypto from "node:crypto";
import authConfig from "./auth.config";
import { connectDB } from "@/lib/db";
import Customer from "@/model/Customer";
import LoyaltyCard from "@/model/LoyaltyCard";

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  session: { strategy: "jwt" },
  callbacks: {
    async jwt({ token, user }) {
      // On initial sign-in `user` is populated; persist the id into the token
      if (user && user.id) {
        token.id = user.id;

        try {
          await connectDB();

          let customer = await Customer.findOne({ googleId: user.id });

          if (!customer) {
            const stampToken = crypto.randomUUID();
            const redeemToken = crypto.randomUUID();

            customer = await Customer.create({
              googleId: user.id,
              name: user.name || "Customer",
              email: user.email || "",
              photo: user.image || undefined,
              stampToken,
              redeemToken,
            });

            await LoyaltyCard.create({
              customerId: customer._id,
              stamps: 0,
            });
          }

          token.id = customer._id.toString();
        } catch (error) {
          console.error("Failed to upsert customer on sign-in:", error);
        }
      }
      return token;
    },
    async session({ session, token }) {
      // Expose the persisted id on the session object for client consumption
      if (session.user) {
        session.user.id = token.id as string;
      }
      return session;
    },
  },
});

