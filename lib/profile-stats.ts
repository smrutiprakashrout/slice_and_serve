export interface ProfileOrder {
  status: string;
}

export interface OrderStats {
  totalOrders: number;
  inProgressOrders: number;
}

export function computeOrderStats(orders: ProfileOrder[] | undefined): OrderStats {
  const customerOrders = orders ?? [];
  return {
    totalOrders: customerOrders.filter(
      (order) => order.status !== "rejected" && order.status !== "cancelled",
    ).length,
    inProgressOrders: customerOrders.filter(
      (order) => order.status === "pending" || order.status === "accepted",
    ).length,
  };
}

export function formatMemberSince(iso: string | undefined): string | null {
  if (!iso) return null;
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleDateString("en-IN", { month: "long", year: "numeric" });
}

export function formatStampProgress(stamps: number, totalRequired: number): string {
  return `${stamps} of ${totalRequired} stamps collected`;
}
