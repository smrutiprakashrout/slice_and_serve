import NextAuth from "next-auth";
import mongoose from "mongoose";
import authConfig from "./auth.config";
import { provisionCustomer } from "@/lib/customer-provisioning";

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  session: { strategy: "jwt" },
  callbacks: {
    async jwt({ token, user, profile }) {
      // Only a successfully provisioned Mongo customer may become a session id.
      if (user) {
        delete token.id;
        try {
          const provisioned = await provisionCustomer({
            googleId: user.id ?? "",
            email: user.email,
            ...(typeof profile?.email_verified === "boolean"
              ? { emailVerified: profile.email_verified }
              : {}),
            name: user.name,
            photo: user.image,
          });
          token.id = provisioned.id;
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          console.error(
            `[auth] Customer provisioning failed for Google account ${user.id ?? "<missing>"}: ${message}`,
          );
          throw error;
        }
      }
      return token;
    },
    async session({ session, token }) {
      // Expose the persisted id on the session object for client consumption
      if (
        session.user &&
        typeof token.id === "string" &&
        token.id.length === 24 &&
        mongoose.isValidObjectId(token.id)
      ) {
        session.user.id = token.id;
      }
      return session;
    },
  },
});

