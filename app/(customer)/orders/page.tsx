"use client";

import Link from "next/link";
import gsap from "gsap";
import { useSession, signIn } from "next-auth/react";
import useSWR from "swr";
import { fetcher } from "@/lib/fetcher";
import { useIsTabVisible } from "@/lib/useIsTabVisible";
import { MOCK_MENU } from "@/lib/menu-data";
import { formatOrderTime } from "@/lib/format-order-time";
import {
  Clock,
  ChefHat,
  CheckCircle2,
  CheckCheck,
  XCircle,
  Package,
  History,
  ReceiptText,
  LogIn,
} from "lucide-react";

// ─── Types ────────────────────────────────────────────────────────────────────

type OrderStatus = "pending" | "accepted" | "completed" | "rejected";
type ItemType = "veg" | "nonveg";

interface ApiOrderItem {
  _id?: string;
  menuItemId: string;
  name: string;
  price: number;
  quantity: number;
}

interface ApiOrder {
  _id: string;
  id?: string;
  customerId: string;
  customerName: string;
  fulfillment: "dine-in" | "pickup";
  tableNumber?: string;
  items: ApiOrderItem[];
  itemTotal: number;
  total: number;
  status: OrderStatus;
  placedAt: string;
  createdAt?: string;
  updatedAt?: string;
}

interface OrderItem {
  id: string;
  orderId: string;
  name: string;
  image: string;
  price: number;
  quantity: number;
  status: OrderStatus;
  type: ItemType;
  placedAt: string;
  fulfillment?: "dine-in" | "pickup";
  tableNumber?: string;
  orderMongoId?: string;
}

// ─── Menu lookup for item images and diet type ────────────────────────────────

const MENU_LOOKUP = new Map<string, { image: string; type: ItemType }>();
for (const m of MOCK_MENU) {
  MENU_LOOKUP.set(m.name.toLowerCase().trim(), {
    image: m.image,
    type: m.type === "non-veg" ? "nonveg" : "veg",
  });
}

const STATUS_CONFIG: Record<
  OrderStatus,
  { label: string; icon: React.ElementType; pillClass: string }
> = {
  pending: { label: "Pending", icon: Clock, pillClass: "border-[#fcd34d] bg-[#fef3c7] text-[#92400e]" },
  accepted: { label: "Accepted", icon: ChefHat, pillClass: "border-yellow-900 bg-yellow-900 text-[#fdc647]" },
  completed: { label: "Completed", icon: CheckCheck, pillClass: "border-[#86efac] bg-[#dcfce7] text-[#166534]" },
  rejected: { label: "Rejected", icon: XCircle, pillClass: "border-[#fca5a5] bg-[#fee2e2] text-[#991b1b]" },
};

const STEPS = ["Placed", "Accepted", "Ready"] as const;

function StatusPill({ status }: { status: OrderStatus }) {
  const config = STATUS_CONFIG[status];
  const StatusIcon = config.icon;

  return (
    <span
      role="status"
      aria-label={`Order status: ${config.label}`}
      className={`inline-flex h-8 items-center gap-2 rounded-full border px-3 text-xs font-bold ${config.pillClass}`}
    >
      <StatusIcon aria-hidden="true" className="h-4 w-4" strokeWidth={2.4} />
      {config.label}
    </span>
  );
}

function StatusTrack({ status, hero = false }: { status: OrderStatus; hero?: boolean }) {
  if (status !== "pending" && status !== "accepted") return null;

  const reachedCount = status === "pending" ? 1 : 2;
  const textReached = hero ? "text-[#fdc647]" : "text-yellow-900";
  const textUpcoming = hero ? "text-[#fff1e3]/80" : "text-yellow-900/75";

  return (
    <div
      role="group"
      aria-label={`Order progress: ${status === "pending" ? "Placed" : "Accepted"}`}
      className="mt-5 flex items-start"
    >
      {STEPS.map((step, index) => {
        const reached = index < reachedCount;
        const isCurrent = index === reachedCount - 1;

        return (
          <div
            key={step}
            className={`flex items-start ${index < STEPS.length - 1 ? "flex-1" : "shrink-0"}`}
          >
            <div
              className="flex w-[72px] shrink-0 flex-col items-center gap-2"
              aria-current={isCurrent ? "step" : undefined}
            >
              <span
                className={`flex h-5 w-5 items-center justify-center rounded-full border-2 transition-colors duration-500 ${
                  reached
                    ? "border-[#fdc647] bg-[#fdc647]"
                    : hero
                      ? "border-[#f0d9b5]/60 bg-transparent"
                      : "border-[#f0d9b5] bg-[#f5e6d0]"
                }`}
              >
                {reached && (
                  <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-yellow-900" />
                )}
              </span>
              <span className={`text-xs font-semibold ${reached ? textReached : textUpcoming}`}>
                {step}
              </span>
            </div>
            {index < STEPS.length - 1 && (
              <span
                aria-hidden="true"
                className={`mt-[9px] h-1 flex-1 overflow-hidden rounded-full ${
                  hero ? "bg-[#fff1e3]/25" : "bg-[#f0d9b5]"
                }`}
              >
                <span
                  className={`block h-full rounded-full bg-[#fdc647] transition-[width] duration-700 ease-out ${
                    index < reachedCount - 1 ? "w-full" : "w-0"
                  }`}
                />
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
}

function OrderCard({
  order,
  hero = false,
  completionId,
  onMarkCompleted,
}: {
  order: ApiOrder;
  hero?: boolean;
  completionId?: string;
  onMarkCompleted?: (id: string) => void;
}) {
  const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);
  const itemSummary = order.items.map((item) => `${item.quantity}× ${item.name}`).join(", ");
  const isAccepted = order.status === "accepted";

  return (
    <article
      data-status={order.status}
      className={`order-card relative overflow-hidden rounded-2xl border p-4 shadow-sm ${
        hero
          ? "border-yellow-900 bg-yellow-900 text-[#fff1e3] shadow-yellow-900/15"
          : "border-[#f0d9b5] bg-white text-yellow-900"
      }`}
    >
      {hero && (
        <span
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 opacity-60"
          style={{
            backgroundImage: "radial-gradient(circle at 1px 1px, rgba(255,241,227,0.10) 1px, transparent 0)",
            backgroundSize: "18px 18px",
          }}
        />
      )}
      <div className="relative">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              <ReceiptText
                aria-hidden="true"
                className={`h-4 w-4 shrink-0 ${hero ? "text-[#fdc647]" : "text-yellow-900/70"}`}
              />
              <h2 className={`truncate text-sm font-bold ${hero ? "text-[#fff1e3]" : "text-yellow-900"}`}>
                Order #{order._id.slice(-6).toUpperCase()}
              </h2>
            </div>
            <p className={`mt-1 text-sm ${hero ? "text-[#fff1e3]/80" : "text-yellow-900/70"}`}>
              {formatOrderTime(order.placedAt)}
            </p>
            <p className={`mt-1 text-xs ${hero ? "text-[#fff1e3]/80" : "text-yellow-900/70"}`}>
              {order.fulfillment === "dine-in"
                ? order.tableNumber
                  ? `Dine-in · Table ${order.tableNumber}`
                  : "Dine-in"
                : "Pickup"}
            </p>
          </div>
          <div className="flex shrink-0 flex-col items-end gap-2">
            <StatusPill status={order.status} />
            <p className={`text-base font-semibold ${hero ? "text-[#fdc647]" : "text-yellow-900"}`}>
              ₹{order.total.toLocaleString("en-IN")}
            </p>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between gap-3">
          <p
            className={`min-w-0 truncate text-sm font-medium ${hero ? "text-[#fff1e3]" : "text-yellow-900"}`}
            title={itemSummary}
          >
            {itemSummary}
          </p>
          {hero && (
            <span className="shrink-0 text-xs font-medium text-[#fff1e3]/80">
              {itemCount} item{itemCount === 1 ? "" : "s"}
            </span>
          )}
        </div>

        <StatusTrack status={order.status} hero={hero} />

        {isAccepted && completionId && onMarkCompleted && (
          <button
            type="button"
            onClick={() => onMarkCompleted(completionId)}
            className={`mt-4 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2 ${
              hero
                ? "bg-[#fdc647] text-yellow-900 hover:bg-[#f5e6d0]"
                : "bg-yellow-900 text-[#fff1e3] hover:bg-yellow-900/90"
            }`}
          >
            <CheckCircle2 aria-hidden="true" className="h-4 w-4" />
            Mark as Completed
          </button>
        )}
      </div>
    </article>
  );
}

function OrderSkeleton() {
  return (
    <div className="rounded-2xl border border-[#f0d9b5] bg-white p-4 shadow-sm">
      <div className="animate-pulse">
        <div className="flex items-start justify-between gap-4">
          <div className="w-2/5 space-y-2">
            <div className="h-4 rounded bg-[#f0d9b5]" />
            <div className="h-3 w-3/4 rounded bg-[#f5e6d0]" />
          </div>
          <div className="h-10 w-24 rounded-full bg-[#f5e6d0]" />
        </div>
        <div className="mt-5 h-4 w-4/5 rounded bg-[#f5e6d0]" />
        <div className="mt-5 h-2 rounded-full bg-[#f0d9b5]" />
      </div>
    </div>
  );
}

function EmptyOrders() {
  return (
    <div className="flex flex-col items-center justify-center px-8 py-20 text-center">
      <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-full bg-[#f5e6d0]">
        <Package aria-hidden="true" className="h-9 w-9 text-yellow-900" />
      </div>
      <h2 className="font-display text-2xl font-bold text-yellow-900">No orders yet</h2>
      <p className="mt-2 text-sm text-yellow-900/75">Your orders will show up here.</p>
      <Link
        href="/"
        className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl bg-[#fdc647] px-6 text-sm font-bold text-yellow-900 transition-colors hover:bg-[#f5e6d0] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-yellow-900 focus-visible:ring-offset-2"
      >
        Browse menu
      </Link>
    </div>
  );
}

function OrdersPageStyles() {
  return (
    <style>{`
      @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;900&display=swap');
      .orders-page .font-display { font-family: 'Playfair Display', Georgia, serif; }
      @keyframes order-card-appear {
        from { opacity: 0; transform: translateY(8px) scale(0.99); }
        to { opacity: 1; transform: translateY(0) scale(1); }
      }
      @media (prefers-reduced-motion: no-preference) {
        .orders-page .order-card { animation: order-card-appear 0.32s ease-out both; }
      }
      .orders-page button:focus-visible {
        outline: 3px solid #fdc647;
        outline-offset: 3px;
      }
    `}</style>
  );
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

export default function OrdersPage() {
  const { status: authStatus } = useSession();
  const isSignedIn = authStatus === "authenticated";
  const isTabVisible = useIsTabVisible();

  const {
    data: apiOrders,
    error,
    isLoading,
    mutate,
  } = useSWR<ApiOrder[]>(
    isSignedIn ? "/api/orders/me" : null,
    fetcher,
    {
      refreshInterval: isTabVisible ? 5000 : 0,
      revalidateOnFocus: true,
    },
  );

  // Transform SWR response mapping Mongo _id -> id to match OrderItem expectations
  const allItems: OrderItem[] = (apiOrders ?? []).flatMap((order) => {
    const placedAtFormatted = formatOrderTime(order.placedAt);
    const orderId = order._id.slice(-6).toUpperCase();

    return order.items.map((it, idx) => {
      const lookup = MENU_LOOKUP.get(it.name.toLowerCase().trim());
      const id =
        order.items.length > 1 ? `${order._id}-${it._id || idx}` : order._id;

      return {
        id,
        orderId,
        name: it.name,
        image: lookup?.image || "/images/burger.jpg",
        price: it.price,
        quantity: it.quantity,
        status: order.status,
        type: lookup?.type || "veg",
        placedAt: placedAtFormatted,
        fulfillment: order.fulfillment,
        tableNumber: order.tableNumber,
        orderMongoId: order._id,
      };
    });
  });

  const orders = allItems.filter(
    (order) => order.status === "pending" || order.status === "accepted",
  );

  const handleMarkCompleted = (id: string) => {
    const target = orders.find((order) => order.id === id);
    if (!target) return;

    const applyCompletion = () => {
      mutate(
        (prev) => {
          if (!prev) return prev;
          return prev.map((order) => {
            if (order._id === target.orderMongoId || order._id === target.id) {
              return { ...order, status: "completed" as const };
            }
            return order;
          });
        },
        { revalidate: false },
      );
    };

    const cardEl = document.getElementById(`order-card-${id}`);
    if (cardEl && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      gsap.to(cardEl, {
        x: 60,
        opacity: 0,
        height: 0,
        paddingTop: 0,
        paddingBottom: 0,
        marginBottom: 0,
        duration: 0.4,
        ease: "power2.in",
        onComplete: applyCompletion,
      });
    } else {
      applyCompletion();
    }
  };

  const allOrders = apiOrders ?? [];
  const activeOrders = allOrders
    .filter((order) => order.status === "pending" || order.status === "accepted")
    .sort(
      (first, second) =>
        new Date(second.placedAt).getTime() - new Date(first.placedAt).getTime(),
    );
  const heroOrder = activeOrders[0];
  const otherOrders = allOrders.filter((order) => order._id !== heroOrder?._id);
  const alsoInProgress = otherOrders
    .filter((order) => order.status === "pending" || order.status === "accepted")
    .sort(
      (first, second) =>
        new Date(second.placedAt).getTime() - new Date(first.placedAt).getTime(),
    );
  const pastOrders = otherOrders
    .filter((order) => order.status === "completed" || order.status === "rejected")
    .sort(
      (first, second) =>
        new Date(second.placedAt).getTime() - new Date(first.placedAt).getTime(),
    );

  if (authStatus === "loading") {
    return (
      <>
        <OrdersPageStyles />
        <main className="orders-page min-h-dvh bg-[#fff1e3] px-5 pb-32 pt-[120px]">
          <div className="mx-auto max-w-md space-y-4">
            {[0, 1, 2].map((key) => (
              <OrderSkeleton key={key} />
            ))}
          </div>
        </main>
      </>
    );
  }

  if (!isSignedIn) {
    return (
      <>
        <OrdersPageStyles />
        <main className="orders-page flex min-h-dvh flex-col items-center justify-center bg-[#fff1e3] px-8 pb-32 pt-[120px] text-center">
          <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-full border border-[#f0d9b5] bg-white">
            <Package aria-hidden="true" className="h-9 w-9 text-yellow-900" />
          </div>
          <h1 className="font-display text-2xl font-bold text-yellow-900">
            You&apos;re not signed in
          </h1>
          <p className="mt-2 max-w-xs text-sm text-yellow-900/75">
            Sign in with Google to view and track your orders.
          </p>
          <button
            onClick={() => signIn("google", { callbackUrl: "/orders" })}
            className="mt-6 flex min-h-11 w-full max-w-xs items-center justify-center gap-3 rounded-2xl bg-yellow-900 text-sm font-semibold text-[#fff1e3] transition-colors hover:bg-yellow-900/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
          >
            <LogIn aria-hidden="true" className="h-5 w-5" />
            Continue with Google
          </button>
        </main>
      </>
    );
  }

  if (error && (error as Error & { status?: number }).status === 401) {
    return (
      <>
        <OrdersPageStyles />
        <main className="orders-page flex min-h-dvh flex-col items-center justify-center bg-[#fff1e3] px-8 pb-32 pt-[120px] text-center">
          <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-full border border-[#f0d9b5] bg-white">
            <Package aria-hidden="true" className="h-9 w-9 text-yellow-900" />
          </div>
          <h1 className="font-display text-2xl font-bold text-yellow-900">
            Session Expired
          </h1>
          <p className="mt-2 max-w-xs text-sm text-yellow-900/75">
            Your session has expired. Please sign in again to view your orders.
          </p>
          <button
            onClick={() => signIn("google", { callbackUrl: "/orders" })}
            className="mt-6 flex min-h-11 w-full max-w-xs items-center justify-center gap-3 rounded-2xl bg-yellow-900 text-sm font-semibold text-[#fff1e3] transition-colors hover:bg-yellow-900/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
          >
            <LogIn aria-hidden="true" className="h-5 w-5" />
            Sign In
          </button>
        </main>
      </>
    );
  }

  const completionIdFor = (order: ApiOrder) =>
    orders.find((item) => item.orderMongoId === order._id)?.id;

  return (
    <>
      <OrdersPageStyles />
      <main className="orders-page min-h-dvh bg-[#fff1e3] px-5 pb-32 pt-[120px]">
        <div className="mx-auto max-w-md">
          <header className="mb-5">
            <h1 className="font-display text-2xl font-bold text-yellow-900">
              My Orders
            </h1>
            <p className="mt-1 text-sm text-yellow-900/75">
              {isLoading
                ? "Loading your orders..."
                : "Your recent orders"}
            </p>
          </header>

          {isLoading ? (
            <div className="space-y-4">
              {[0, 1, 2].map((key) => (
                <OrderSkeleton key={key} />
              ))}
            </div>
          ) : error ? (
            <div className="rounded-2xl border border-[#f0d9b5] bg-white p-6 text-center shadow-sm">
              <p className="text-sm font-semibold text-yellow-900">
                Failed to load orders
              </p>
              <p className="mt-2 text-sm text-yellow-900/75">
                {error?.message || "Please check your connection and try again."}
              </p>
              <button
                type="button"
                onClick={() => mutate()}
                className="mt-5 min-h-11 rounded-xl bg-yellow-900 px-5 text-sm font-semibold text-[#fff1e3] transition-colors hover:bg-yellow-900/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
              >
                Try Again
              </button>
            </div>
          ) : allOrders.length === 0 ? (
            <EmptyOrders />
          ) : (
            <div className="space-y-6">
              {heroOrder && (
                <div
                  id={`order-card-${completionIdFor(heroOrder)}`}
                  key={`${heroOrder._id}-${heroOrder.status}`}
                >
                  <OrderCard
                    order={heroOrder}
                    hero
                    completionId={completionIdFor(heroOrder)}
                    onMarkCompleted={handleMarkCompleted}
                  />
                </div>
              )}

              {alsoInProgress.length > 0 && (
                <section aria-labelledby="also-in-progress-title">
                  <div className="mb-3 flex items-center gap-2">
                    <History aria-hidden="true" className="h-4 w-4 text-yellow-900/65" />
                    <h2
                      id="also-in-progress-title"
                      className="font-display text-xl font-bold text-yellow-900"
                    >
                      Also in progress
                    </h2>
                  </div>
                  <div className="space-y-3">
                    {alsoInProgress.map((order) => {
                      const completionId = completionIdFor(order);
                      return (
                        <div
                          key={`${order._id}-${order.status}`}
                          id={completionId ? `order-card-${completionId}` : undefined}
                        >
                          <OrderCard
                            order={order}
                            completionId={completionId}
                            onMarkCompleted={handleMarkCompleted}
                          />
                        </div>
                      );
                    })}
                  </div>
                </section>
              )}

              {pastOrders.length > 0 && (
                <section aria-labelledby="past-orders-title">
                  <div className="mb-3 flex items-center gap-2">
                    <History aria-hidden="true" className="h-4 w-4 text-yellow-900/65" />
                    <h2
                      id="past-orders-title"
                      className="font-display text-xl font-bold text-yellow-900"
                    >
                      Past orders
                    </h2>
                  </div>
                  <div className="space-y-3">
                    {pastOrders.map((order) => {
                      const completionId = completionIdFor(order);
                      return (
                        <div
                          key={`${order._id}-${order.status}`}
                          id={completionId ? `order-card-${completionId}` : undefined}
                        >
                          <OrderCard
                            order={order}
                            completionId={completionId}
                            onMarkCompleted={handleMarkCompleted}
                          />
                        </div>
                      );
                    })}
                  </div>
                </section>
              )}
            </div>
          )}
        </div>
      </main>
    </>
  );
}
