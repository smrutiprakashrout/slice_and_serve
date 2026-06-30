"use client";

import { useEffect, useRef, useState } from "react";

const THRESHOLD = 5; // px — ignore tiny scroll noise (trackpad/momentum jitter)
const HIDE_AFTER = 60; // px — don't hide until scrolled past ~the bar's own height

/**
 * Tracks scroll direction across ALL elements matching the selector and
 * returns whether a hide-on-scroll-down UI element (e.g. TopBar) should
 * currently be visible.
 *
 * Why "all" matching elements: some pages scroll the layout's own
 * [data-scroll-container] (app/(customer)/layout.tsx), while others
 * (e.g. the menu page) have their own nested overflow-y-auto div that
 * does the actual scrolling instead. Listening on every match means the
 * hook works correctly regardless of which element is the real scroller
 * on a given page — no per-page wiring needed beyond adding the attribute.
 */
export function useScrollDirection(
  selector: string = "[data-scroll-container]",
) {
  const [visible, setVisible] = useState(true);
  const lastY = useRef<Map<Element, number>>(new Map());
  const ticking = useRef<Map<Element, boolean>>(new Map());

  useEffect(() => {
    const containers = Array.from(
      document.querySelectorAll<HTMLElement>(selector),
    );
    if (containers.length === 0) return;

    containers.forEach((c) => lastY.current.set(c, c.scrollTop));

    function makeHandler(container: HTMLElement) {
      return function onScroll() {
        if (ticking.current.get(container)) return;
        ticking.current.set(container, true);

        requestAnimationFrame(() => {
          const currentY = container.scrollTop;
          const prevY = lastY.current.get(container) ?? 0;
          const diff = currentY - prevY;

          if (Math.abs(diff) > THRESHOLD) {
            if (diff > 0 && currentY > HIDE_AFTER) {
              setVisible(false);
            } else if (diff < 0) {
              setVisible(true);
            }
            lastY.current.set(container, currentY);
          }

          ticking.current.set(container, false);
        });
      };
    }

    const handlers = containers.map((c) => ({
      container: c,
      handler: makeHandler(c),
    }));

    handlers.forEach(({ container, handler }) =>
      container.addEventListener("scroll", handler, { passive: true }),
    );

    return () => {
      handlers.forEach(({ container, handler }) =>
        container.removeEventListener("scroll", handler),
      );
      lastY.current.clear();
      ticking.current.clear();
    };
  }, [selector]);

  return visible;
}
