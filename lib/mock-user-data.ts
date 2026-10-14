// lib/mock-user-data.ts
// Mock data — replace with real database queries once a DB is added.
// Shape is intentionally realistic so swapping the data source later
// requires no changes to the components that consume it.

export type Order = {
  id: string;
  date: string; // ISO 8601
  items: string[];
  total: number;
  status: "delivered" | "preparing" | "cancelled";
};

const now = Date.now();
const daysAgo = (n: number) =>
  new Date(now - n * 24 * 60 * 60 * 1000).toISOString();

// Spread across ~10 days so the 7-day filter has something to exclude —
// proves filtering logic actually works rather than trivially passing everything.
const ALL_MOCK_ORDERS: Order[] = [
  {
    id: "ord_001",
    date: daysAgo(1),
    items: ["Chicken 65 Sandwich", "Cold Coffee"],
    total: 280,
    status: "delivered",
  },
  {
    id: "ord_002",
    date: daysAgo(2),
    items: ["Chilli Chicken Sandwich", "Mango Shake"],
    total: 320,
    status: "delivered",
  },
  {
    id: "ord_003",
    date: daysAgo(4),
    items: ["Classic Veg Sandwich", "Paneer Sandwich"],
    total: 260,
    status: "delivered",
  },
  {
    id: "ord_004",
    date: daysAgo(6),
    items: ["Egg Sandwich"],
    total: 130,
    status: "delivered",
  },
  {
    id: "ord_005",
    date: daysAgo(8), // ← outside 7-day window; proves the filter works
    items: ["Chilli Mushroom Sandwich", "Cheese & Corn Sandwich"],
    total: 310,
    status: "delivered",
  },
  {
    id: "ord_006",
    date: daysAgo(10), // ← also outside 7-day window
    items: ["Nutella Sandwich"],
    total: 150,
    status: "cancelled",
  },
];

// TODO: replace this function's body with a real DB query when a database is added.
// e.g. `db.order.findMany({ where: { userId, date: { gte: sevenDaysAgo } } })`
// Keep the function signature the same so ProfilePage doesn't need to change.
export function getRecentOrders(_userEmail: string | null | undefined): Order[] {
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
  return ALL_MOCK_ORDERS.filter(
    (o) => new Date(o.date).getTime() >= sevenDaysAgo,
  );
}

// TODO: replace memberSince with real account creation date from the DB.
// TODO: replace stamps with real loyalty stamp count from the DB.
export const MOCK_LOYALTY = {
  memberSince: "March 2024", // TODO: replace with real account creation date
  stamps: 3, // TODO: replace with real loyalty stamp count from the DB
  totalOrders: 12, // TODO: replace with real order count from the DB
};
