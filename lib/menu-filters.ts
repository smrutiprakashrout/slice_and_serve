export function filterVegOnly<T extends { type: string }>(
  items: T[],
  vegOnly: boolean,
): T[] {
  return vegOnly ? items.filter((item) => item.type === "veg") : items;
}
