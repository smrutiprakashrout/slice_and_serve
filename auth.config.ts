import Google from "next-auth/providers/google";
import type { NextAuthConfig } from "next-auth";

// This file is intentionally free of any Node.js-only imports (no DB, no fs,
// no Prisma) so it can be safely imported from proxy.ts, which runs in the
// edge-compatible runtime.
export default {
  providers: [Google],
  pages: {
    signIn: "/login",
    error: "/login",
  },
} satisfies NextAuthConfig;
