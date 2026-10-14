"use client";

import { useEffect, useState } from "react";

/**
 * Custom hook that tracks whether the browser tab is currently visible
 * using the Page Visibility API (document.visibilityState).
 *
 * Returns true if the tab is visible (or during SSR), false when hidden/backgrounded.
 */
export function useIsTabVisible(): boolean {
  const [isVisible, setIsVisible] = useState<boolean>(() => {
    if (typeof document !== "undefined") {
      return document.visibilityState === "visible";
    }
    return true;
  });

  useEffect(() => {
    if (typeof document === "undefined") return;

    const handleVisibilityChange = () => {
      setIsVisible(document.visibilityState === "visible");
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);

    // Sync on mount
    setIsVisible(document.visibilityState === "visible");

    return () => {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    };
  }, []);

  return isVisible;
}

export default useIsTabVisible;
