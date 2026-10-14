import { NextResponse } from "next/server";

export class ApiError extends Error {
  status: number;
  code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

/**
 * Standard API error handler returning a consistent { error: { code, message } } response.
 * Safely masks unexpected internal errors to prevent leaking database details or stack traces.
 */
export function handleApiError(err: unknown): NextResponse {
  if (err instanceof ApiError) {
    return NextResponse.json(
      {
        error: {
          code: err.code,
          message: err.message,
        },
      },
      { status: err.status },
    );
  }

  // Unexpected error — log full error server-side, return generic 500
  console.error("Unhandled API error:", err);
  return NextResponse.json(
    {
      error: {
        code: "INTERNAL_ERROR",
        message: "Something went wrong.",
      },
    },
    { status: 500 },
  );
}

export default handleApiError;
