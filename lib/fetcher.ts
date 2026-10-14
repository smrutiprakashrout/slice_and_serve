/**
 * Shared fetcher function for SWR client-side requests.
 * Throws an error with the response message or status text on non-2xx responses.
 */
export const fetcher = async <T = unknown>(url: string): Promise<T> => {
  const res = await fetch(url);

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    const message =
      errorData?.error?.message ||
      `An error occurred while fetching data (${res.status})`;
    const error = new Error(message);
    (error as Error & { status?: number }).status = res.status;
    throw error;
  }

  return res.json();
};

export default fetcher;
