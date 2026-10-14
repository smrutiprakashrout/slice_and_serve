interface RateLimitEntry {
  count: number;
  resetTime: number; // epoch ms when the rate limit window expires
}

declare global {
  // eslint-disable-next-line no-var
  var loginRateLimitMap: Map<string, RateLimitEntry> | undefined;
}

/**
 * In-memory rate limiter for admin login (5 attempts per 15 minutes per IP).
 *
 * NOTE: Because this is stored in-memory, counts reset whenever the serverless
 * function cold-starts or when a new container spins up, since memory is not
 * shared across serverless instances. This is an intentional and accepted
 * tradeoff for this single-admin app on free-tier hosting (no Redis or external
 * database needed).
 */
const WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const MAX_FAILED_ATTEMPTS = 5;

const attemptsMap: Map<string, RateLimitEntry> =
  globalThis.loginRateLimitMap ??
  (globalThis.loginRateLimitMap = new Map<string, RateLimitEntry>());

/**
 * Extracts client IP from standard forwarded-for headers with a sane fallback.
 */
export function getClientIp(request: Request): string {
  const forwardedFor = request.headers.get("x-forwarded-for");
  if (forwardedFor) {
    return forwardedFor.split(",")[0].trim();
  }
  const realIp = request.headers.get("x-real-ip");
  if (realIp) {
    return realIp.trim();
  }
  return "127.0.0.1";
}

/**
 * Checks if the IP has exceeded the allowed failed attempts within the window.
 */
export function isRateLimited(ip: string): {
  limited: boolean;
  retryAfterSeconds: number;
} {
  const now = Date.now();
  const entry = attemptsMap.get(ip);

  if (!entry) {
    return { limited: false, retryAfterSeconds: 0 };
  }

  // If window expired, clean up entry
  if (now >= entry.resetTime) {
    attemptsMap.delete(ip);
    return { limited: false, retryAfterSeconds: 0 };
  }

  if (entry.count >= MAX_FAILED_ATTEMPTS) {
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((entry.resetTime - now) / 1000),
    );
    return { limited: true, retryAfterSeconds };
  }

  return { limited: false, retryAfterSeconds: 0 };
}

/**
 * Records a failed login attempt for the given IP.
 */
export function recordFailedAttempt(ip: string): void {
  const now = Date.now();
  const entry = attemptsMap.get(ip);

  if (!entry || now >= entry.resetTime) {
    attemptsMap.set(ip, { count: 1, resetTime: now + WINDOW_MS });
  } else {
    entry.count += 1;
  }
}

/**
 * Resets failed attempts for the given IP upon successful login.
 */
export function resetRateLimit(ip: string): void {
  attemptsMap.delete(ip);
}
