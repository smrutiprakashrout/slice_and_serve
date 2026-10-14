// proxy.ts — Next.js 16 edge-proxy file (replaces the deprecated middleware.ts)
// Auth.js v5: import ONLY auth.config here (not auth.ts) to avoid pulling
// Node.js-only code (adapters, DB clients) into this runtime boundary.
import NextAuth from "next-auth";
import authConfig from "./auth.config";
import type { NextRequest } from "next/server";

const { auth } = NextAuth(authConfig);

// NOTE: /profile is intentionally NOT in the matcher here.
// Rationale: /profile has its own polished signed-out empty-state UI that
// should render when the user is unauthenticated. If the proxy redirected
// unauthenticated users away from /profile, that carefully-crafted UI would
// never be seen. Instead, /profile relies on its own client-side session check
// via useSession(). The proxy matcher is left here for future API routes that
// need edge-level auth protection (add them to the array below when needed).
export default function proxy(request: NextRequest) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return auth(request as unknown as Parameters<typeof auth>[0]);
}

export const config = {
  // Only run proxy on protected API routes — expand this array as you add
  // server-side protected routes. Customer-facing pages (/profile, /orders,
  // /loyalty, /cart) manage their own auth state via useSession().
  matcher: ["/api/protected/:path*"],
};
