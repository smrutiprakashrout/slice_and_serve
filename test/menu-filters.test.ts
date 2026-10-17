import { describe, expect, it } from "vitest";
import { filterVegOnly } from "@/lib/menu-filters";

describe("filterVegOnly", () => {
  const items = [
    { id: "1", type: "veg" },
    { id: "2", type: "non-veg" },
    { id: "3", type: "veg" },
  ];

  it("keeps only vegetarian items when enabled", () => {
    expect(filterVegOnly(items, true)).toEqual([
      { id: "1", type: "veg" },
      { id: "3", type: "veg" },
    ]);
  });

  it("returns all items unchanged when disabled", () => {
    expect(filterVegOnly(items, false)).toBe(items);
  });
});
