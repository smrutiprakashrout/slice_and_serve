"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import Image from "next/image";
import { useSession, signIn } from "next-auth/react";
import useSWR from "swr";
import { fetcher } from "@/lib/fetcher";
import { useIsTabVisible } from "@/lib/useIsTabVisible";
import { MOCK_MENU } from "@/lib/menu-data";
import {
  Clock,
  ChefHat,
  CheckCircle2,
  XCircle,
  Package,
  History,
  ReceiptText,
  Star,
  LogIn,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

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

function formatOrderTime(dateInput: string | Date | undefined): string {
  if (!dateInput) return "";
  try {
    const d = new Date(dateInput);
    if (isNaN(d.getTime())) return String(dateInput);
    const now = new Date();
    const isToday =
      d.getDate() === now.getDate() &&
      d.getMonth() === now.getMonth() &&
      d.getFullYear() === now.getFullYear();

    const timeStr = d.toLocaleTimeString([], {
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    });

    if (isToday) return timeStr;
    const dateStr = d.toLocaleDateString([], {
      month: "short",
      day: "numeric",
    });
    return `${dateStr}, ${timeStr}`;
  } catch {
    return String(dateInput);
  }
}

// ─── Status config ────────────────────────────────────────────────────────────

const STATUS_CONFIG: Record<
  OrderStatus,
  {
    label: string;
    icon: React.ElementType;
    step: number;
    color: string;
    bg: string;
    pulse: boolean;
  }
> = {
  pending: {
    label: "Pending",
    icon: Clock,
    step: 1,
    color: "text-amber-600",
    bg: "bg-amber-50 border-amber-200",
    pulse: false,
  },
  accepted: {
    label: "Accepted",
    icon: ChefHat,
    step: 2,
    color: "text-blue-600",
    bg: "bg-blue-50 border-blue-200",
    pulse: true,
  },
  completed: {
    label: "Completed",
    icon: CheckCircle2,
    step: 3,
    color: "text-green-600",
    bg: "bg-green-50 border-green-200",
    pulse: false,
  },
  rejected: {
    label: "Rejected",
    icon: XCircle,
    step: 0,
    color: "text-red-600",
    bg: "bg-red-50 border-red-200",
    pulse: false,
  },
};

const STEPS: { key: "pending" | "accepted" | "completed"; label: string }[] = [
  { key: "pending", label: "Placed" },
  { key: "accepted", label: "Accepted" },
  { key: "completed", label: "Completed" },
];

// ─── Sub-components ───────────────────────────────────────────────────────────

function VegBadge({ type }: { type: ItemType }) {
  return (
    <div
      className={`w-4 h-4 border-2 rounded-[3px] flex items-center justify-center shrink-0
        ${type === "veg" ? "border-green-600" : "border-red-500"}`}
    >
      <div
        className={`w-2 h-2 rounded-full
          ${type === "veg" ? "bg-green-600" : "bg-red-500"}`}
      />
    </div>
  );
}

function StatusTrack({ status }: { status: OrderStatus }) {
  if (status === "rejected") {
    return (
      <div className="flex items-center gap-1.5 mt-3 px-2.5 py-1.5 rounded-lg bg-red-50 border border-red-200 w-fit">
        <XCircle className="w-3.5 h-3.5 text-red-600" />
        <span className="text-[10px] font-bold text-red-600">Order Rejected</span>
      </div>
    );
  }

  const currentStep = STATUS_CONFIG[status].step;

  return (
    <div className="flex items-center gap-0 mt-3">
      {STEPS.map((step, i) => {
        const done = STATUS_CONFIG[step.key].step <= currentStep;
        const active = step.key === status;
        const isLast = i === STEPS.length - 1;

        return (
          <div
            key={step.key}
            className="flex items-center flex-1 last:flex-none"
          >
            {/* Node */}
            <div className="flex flex-col items-center gap-1">
              <div
                className={`w-5 h-5 rounded-full flex items-center justify-center border-2 transition-all duration-500
                  ${
                    done
                      ? active && status === "completed"
                        ? "bg-green-700 border-green-700 shadow-md"
                        : "bg-[#c17f24] border-[#c17f24]"
                      : "bg-white border-gray-200"
                  }`}
              >
                {done && (
                  <div className="w-2 h-2 rounded-full bg-white" />
                )}
              </div>
              <p
                className={`text-[8px] font-bold leading-none whitespace-nowrap
                ${done ? (active && status === "completed" ? "text-green-600" : "text-[#c17f24]") : "text-gray-300"}`}
              >
                {step.label}
              </p>
            </div>
            {/* Connector */}
            {!isLast && (
              <div className="flex-1 h-[2px] mx-1 rounded-full overflow-hidden bg-gray-100 mb-3.5">
                <div
                  className="h-full rounded-full transition-all duration-700 ease-out"
                  style={{
                    width:
                      STATUS_CONFIG[STEPS[i + 1].key].step <= currentStep
                        ? "100%"
                        : "0%",
                    backgroundColor: "#c17f24",
                  }}
                />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

function OrderCard({
  item,
  onMarkCompleted,
}: {
  item: OrderItem;
  onMarkCompleted: (id: string) => void;
}) {
  const cfg = STATUS_CONFIG[item.status];
  const StatusIcon = cfg.icon;
  const cardRef = useRef<HTMLDivElement>(null);

  return (
    <div
      ref={cardRef}
      className={`order-card bg-white rounded-2xl border overflow-hidden shadow-sm border-[#f0d9b5]`}
    >
      {/* Order ID strip */}
      <div className="bg-[#fff1e3] px-4 py-1.5 flex items-center justify-between border-b border-[#f0d9b5]">
        <div className="flex items-center gap-1.5">
          <ReceiptText className="w-3 h-3 text-[#c17f24]" />
          <p className="text-[10px] font-black text-[#3d1a00] tracking-widest uppercase">
            Order #{item.orderId}
          </p>
          {item.fulfillment && (
            <span className="text-[9px] font-bold text-[#c17f24] bg-[#f5e6d0] px-1.5 py-0.5 rounded capitalize">
              {item.fulfillment === "dine-in"
                ? item.tableNumber?.trim()
                  ? `Table ${item.tableNumber.trim()}`
                  : "Dine-in"
                : "Pickup"}
            </span>
          )}
        </div>
        <p className="text-[10px] text-[#3d1a00]/40 font-medium">
          {item.placedAt}
        </p>
      </div>

      {/* Main content */}
      <div className="p-4">
        <div className="flex gap-3">
          {/* Image */}
          <div className="w-20 h-20 rounded-xl overflow-hidden bg-[#f5e6d0] shrink-0 relative">
            <Image
              src={item.image}
              alt={item.name}
              width={100}
              height={100}
              className="w-full h-full object-cover"
            />
          </div>

          {/* Details */}
          <div className="flex-1 min-w-0">
            {/* Name row */}
            <div className="flex items-start gap-2 mb-1">
              <VegBadge type={item.type} />
              <h3 className="font-black text-sm text-[#3d1a00] leading-tight">
                {item.name}
              </h3>
            </div>

            {/* Qty + Price */}
            <div className="flex items-center gap-2 mb-2">
              <span className="text-xs text-[#3d1a00]/50 font-medium">
                Qty: {item.quantity}
              </span>
              <span className="text-[#3d1a00]/20">·</span>
              <span className="text-sm font-black text-[#c17f24]">
                ₹{item.price * item.quantity}
              </span>
            </div>

            {/* Status badge */}
            <div
              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-[11px] font-black ${cfg.bg} ${cfg.color}`}
            >
              <StatusIcon className="w-3 h-3" strokeWidth={2.5} />
              {cfg.label}
            </div>
          </div>
        </div>

        {/* Progress track */}
        <StatusTrack status={item.status} />

        {/* Accepted CTA */}
        {item.status === "accepted" && (
          <button
            onClick={() => onMarkCompleted(item.id)}
            className="mt-4 w-full h-11 bg-[#c17f24] hover:bg-[#a66a1a] text-white font-black text-xs rounded-xl flex items-center justify-center gap-2 active:scale-95 transition-transform"
          >
            <CheckCircle2 className="w-4 h-4" />
            Mark as Completed
          </button>
        )}
      </div>
    </div>
  );
}

function HistoryCard({ item }: { item: OrderItem }) {
  return (
    <div className="history-card bg-white rounded-2xl border border-[#f0d9b5] overflow-hidden shadow-sm opacity-0">
      <div className="bg-[#f5f5f5] px-4 py-1.5 flex items-center justify-between border-b border-gray-100">
        <div className="flex items-center gap-1.5">
          <History className="w-3 h-3 text-gray-400" />
          <p className="text-[10px] font-black text-gray-500 tracking-widest uppercase">
            Order #{item.orderId}
          </p>
          {item.fulfillment && (
            <span className="text-[9px] font-bold text-gray-500 bg-gray-200 px-1.5 py-0.5 rounded capitalize">
              {item.fulfillment === "dine-in"
                ? item.tableNumber?.trim()
                  ? `Table ${item.tableNumber.trim()}`
                  : "Dine-in"
                : "Pickup"}
            </span>
          )}
        </div>
        <p className="text-[10px] text-gray-400 font-medium">{item.placedAt}</p>
      </div>

      <div className="p-4 flex gap-3 items-center">
        <div className="w-14 h-14 rounded-xl overflow-hidden bg-[#f5e6d0] shrink-0 grayscale-[30%]">
          <Image
            src={item.image}
            alt={item.name}
            width={100}
            height={100}
            className="w-full h-full object-cover"
          />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <VegBadge type={item.type} />
            <p className="font-black text-sm text-gray-700 leading-tight truncate">
              {item.name}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-400 font-medium">
              Qty: {item.quantity}
            </span>
            <span className="text-gray-200">·</span>
            <span className="text-sm font-black text-gray-500">
              ₹{item.price * item.quantity}
            </span>
          </div>
        </div>
        <div className="flex flex-col items-end gap-1 shrink-0">
          {item.status === "rejected" ? (
            <div className="flex items-center gap-1 bg-red-50 border border-red-200 rounded-full px-2.5 py-1">
              <XCircle className="w-3 h-3 text-red-600" strokeWidth={2.5} />
              <p className="text-[10px] font-black text-red-600">Rejected</p>
            </div>
          ) : (
            <>
              <div className="flex items-center gap-1 bg-gray-100 rounded-full px-2.5 py-1">
                <CheckCircle2 className="w-3 h-3 text-gray-400" strokeWidth={2.5} />
                <p className="text-[10px] font-black text-gray-400">Completed</p>
              </div>
              {/* Star rating placeholder */}
              <div className="flex gap-0.5">
                {[1, 2, 3, 4, 5].map((s) => (
                  <Star
                    key={s}
                    className="w-2.5 h-2.5 fill-[#f0d9b5] text-[#f0d9b5]"
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function EmptyActive() {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-8 text-center">
      <div className="w-20 h-20 bg-[#f5e6d0] rounded-full flex items-center justify-center mb-5">
        <Package className="w-9 h-9 text-[#c9a87c]" />
      </div>
      <h3 className="font-black text-lg text-[#3d1a00] mb-2">
        No active orders
      </h3>
      <p className="text-sm text-[#3d1a00]/50 leading-relaxed">
        Your active orders will appear here once you place one from the menu.
      </p>
    </div>
  );
}

function EmptyHistory() {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-8 text-center">
      <div className="w-20 h-20 bg-[#f5e6d0] rounded-full flex items-center justify-center mb-5">
        <History className="w-9 h-9 text-[#c9a87c]" />
      </div>
      <h3 className="font-black text-lg text-[#3d1a00] mb-2">
        No order history
      </h3>
      <p className="text-sm text-[#3d1a00]/50 leading-relaxed">
        Completed orders will be saved here automatically.
      </p>
    </div>
  );
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

export default function OrdersPage() {
  const [activeTab, setActiveTab] = useState<"active" | "history">("active");
  const containerRef = useRef<HTMLDivElement>(null);

  const { data: session, status: authStatus } = useSession();
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
    (o) => o.status === "pending" || o.status === "accepted",
  );
  const history = allItems.filter(
    (o) => o.status === "completed" || o.status === "rejected",
  );

  // Entrance animation
  useGSAP(
    () => {
      gsap.from(".order-card", {
        y: 28,
        opacity: 0,
        duration: 0.5,
        stagger: 0.1,
        ease: "power2.out",
      });
    },
    { scope: containerRef, dependencies: [activeTab, orders.length] },
  );

  // History card entrance
  useGSAP(
    () => {
      if (activeTab === "history") {
        gsap.to(".history-card", {
          opacity: 1,
          y: 0,
          duration: 0.45,
          stagger: 0.08,
          ease: "power2.out",
        });
      }
    },
    { scope: containerRef, dependencies: [activeTab, history.length] },
  );

  const handleMarkCompleted = (id: string) => {
    const target = orders.find((o) => o.id === id);
    if (!target) return;

    const applyCompletion = () => {
      mutate(
        (prev) => {
          if (!prev) return prev;
          return prev.map((ord) => {
            if (ord._id === target.orderMongoId || ord._id === target.id) {
              return { ...ord, status: "completed" as const };
            }
            return ord;
          });
        },
        { revalidate: false },
      );
    };

    // Animate card out
    const cardEl = document.getElementById(`order-card-${id}`);
    if (cardEl) {
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

  // Separate active orders by status section
  const accepted = orders.filter((o) => o.status === "accepted");
  const pending = orders.filter((o) => o.status === "pending");

  // ── Auth loading state ──
  if (authStatus === "loading") {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex items-center justify-center">
        <div className="w-10 h-10 border-4 border-[#c17f24] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // ── Signed-out state ──
  if (!isSignedIn) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex flex-col items-center justify-center px-8 text-center pb-28">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-5 shadow-sm border border-[#f0d9b5]">
          <Package className="w-10 h-10 text-[#c17f24]" />
        </div>
        <h2 className="font-black text-2xl text-[#3d1a00] mb-2">
          You&apos;re not signed in
        </h2>
        <p className="text-sm text-[#3d1a00]/50 leading-relaxed mb-8">
          Sign in with Google to view and track your orders.
        </p>
        <button
          onClick={() => signIn("google", { callbackUrl: "/orders" })}
          className="w-full max-w-xs h-14 bg-[#3d1a00] text-white font-black text-sm rounded-2xl flex items-center justify-center gap-3 shadow-lg active:scale-95 transition-transform"
        >
          <LogIn className="w-5 h-5" />
          Continue with Google
        </button>
      </div>
    );
  }

  // ── Session expired (401 from SWR) ──
  if (error && (error as Error & { status?: number }).status === 401) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex flex-col items-center justify-center px-8 text-center pb-28">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-5 shadow-sm border border-[#f0d9b5]">
          <Package className="w-10 h-10 text-[#c17f24]" />
        </div>
        <h2 className="font-black text-2xl text-[#3d1a00] mb-2">
          Session Expired
        </h2>
        <p className="text-sm text-[#3d1a00]/50 leading-relaxed mb-8">
          Your session has expired. Please sign in again to view your orders.
        </p>
        <button
          onClick={() => signIn("google", { callbackUrl: "/orders" })}
          className="w-full max-w-xs h-14 bg-[#3d1a00] text-white font-black text-sm rounded-2xl flex items-center justify-center gap-3 shadow-lg active:scale-95 transition-transform"
        >
          <LogIn className="w-5 h-5" />
          Sign In
        </button>
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="bg-[#fff1e3] min-h-dvh font-sans text-[#3d1a00]"
    >
      {/* ── Page Header ──────────────────────────────────────────── */}
      <div className="px-5 pb-3 pt-28">
        <h1 className="text-2xl font-black text-[#3d1a00] leading-tight">
          My Orders
        </h1>
        <p className="text-xs text-[#3d1a00]/50 mt-0.5">
          {isLoading
            ? "Loading your orders..."
            : orders.length > 0
              ? `${orders.length} active item${orders.length !== 1 ? "s" : ""} · tap "Mark as Completed" when collected`
              : "All clear — no active orders"}
        </p>
      </div>

      {/* ── Tabs ─────────────────────────────────────────────────── */}
      <div className="px-5 pb-3">
        <div className="bg-white rounded-xl p-1 flex border border-[#f0d9b5]">
          {(["active", "history"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 flex items-center justify-center gap-2 h-10 rounded-lg text-xs font-black transition-all duration-300
                ${
                  activeTab === tab
                    ? "bg-[#3d1a00] text-[#fff1e3] shadow-sm"
                    : "text-[#3d1a00]/50 hover:text-[#3d1a00]"
                }`}
            >
              {tab === "active" ? (
                <>
                  <Package className="w-3.5 h-3.5" />
                  Active
                  {!isLoading && orders.length > 0 && (
                    <span
                      className={`w-4 h-4 rounded-full text-[9px] font-black flex items-center justify-center
                      ${activeTab === "active" ? "bg-[#c17f24] text-white" : "bg-[#f0d9b5] text-[#3d1a00]"}`}
                    >
                      {orders.length}
                    </span>
                  )}
                </>
              ) : (
                <>
                  <History className="w-3.5 h-3.5" />
                  History
                  {!isLoading && history.length > 0 && (
                    <span
                      className={`w-4 h-4 rounded-full text-[9px] font-black flex items-center justify-center
                      ${activeTab === "history" ? "bg-[#c17f24] text-white" : "bg-[#f0d9b5] text-[#3d1a00]"}`}
                    >
                      {history.length}
                    </span>
                  )}
                </>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* ── Content: Loading, Error, or Tabs ─────────────────────── */}
      {isLoading ? (
        <div className="px-5 pb-28 space-y-4">
          {[1, 2, 3].map((n) => (
            <div
              key={`skeleton-${n}`}
              className="bg-white rounded-2xl overflow-hidden shadow-sm border border-[#f0d9b5] p-4 animate-pulse"
            >
              <div className="flex gap-3">
                <div className="w-20 h-20 bg-gray-200/80 rounded-xl shrink-0" />
                <div className="flex-1 space-y-2 py-1">
                  <div className="h-4 bg-gray-200 rounded w-3/4" />
                  <div className="h-3 bg-gray-100 rounded w-1/2" />
                  <div className="h-5 bg-gray-200 rounded-full w-20 mt-2" />
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="px-5 pb-28">
          <div className="bg-white/80 border border-yellow-900/20 rounded-2xl p-6 text-center shadow-sm my-6">
            <p className="text-sm font-semibold text-[#3d1a00] mb-1">
              Failed to load orders
            </p>
            <p className="text-xs text-[#3d1a00]/60 mb-4">
              {error?.message || "Please check your connection and try again."}
            </p>
            <button
              type="button"
              onClick={() => mutate()}
              className="px-4 py-2 bg-[#3d1a00] text-white text-xs font-bold rounded-lg hover:bg-[#5a2700] transition-colors"
            >
              Try Again
            </button>
          </div>
        </div>
      ) : (
        <>
          {/* ── Active Tab ───────────────────────────────────────────── */}
          {activeTab === "active" && (
            <div className="px-5 pb-28">
              {orders.length === 0 ? (
                <EmptyActive />
              ) : (
                <div className="space-y-6">
                  {/* Accepted section */}
                  {accepted.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-3">
                        <ChefHat className="w-3.5 h-3.5 text-blue-500" />
                        <p className="text-[10px] font-black tracking-widest uppercase text-blue-700">
                          Accepted &amp; Preparing ({accepted.length})
                        </p>
                      </div>
                      <div className="space-y-3">
                        {accepted.map((item) => (
                          <div
                            key={item.id}
                            id={`order-card-${item.id}`}
                            className="overflow-hidden"
                          >
                            <OrderCard
                              item={item}
                              onMarkCompleted={handleMarkCompleted}
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Pending section */}
                  {pending.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-3">
                        <Clock className="w-3.5 h-3.5 text-amber-500" />
                        <p className="text-[10px] font-black tracking-widest uppercase text-amber-700">
                          Waiting ({pending.length})
                        </p>
                      </div>
                      <div className="space-y-3">
                        {pending.map((item) => (
                          <div
                            key={item.id}
                            id={`order-card-${item.id}`}
                            className="overflow-hidden"
                          >
                            <OrderCard
                              item={item}
                              onMarkCompleted={handleMarkCompleted}
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ── History Tab ──────────────────────────────────────────── */}
          {activeTab === "history" && (
            <div className="px-5 pb-28">
              {history.length === 0 ? (
                <EmptyHistory />
              ) : (
                <div className="space-y-3">
                  {/* Summary strip */}
                  <div className="bg-[#3d1a00] rounded-2xl px-5 py-3.5 flex items-center justify-between mb-4">
                    <div>
                      <p className="text-[#c9a87c] text-[10px] font-black tracking-widest uppercase">
                        Total Spent
                      </p>
                      <p className="text-[#fff1e3] font-black text-xl">
                        ₹
                        {history
                          .filter((o) => o.status === "completed")
                          .reduce((sum, o) => sum + o.price * o.quantity, 0)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-[#c9a87c] text-[10px] font-black tracking-widest uppercase">
                        Items
                      </p>
                      <p className="text-[#fff1e3] font-black text-xl">
                        {history.length}
                      </p>
                    </div>
                  </div>

                  {history.map((item) => (
                    <div key={item.id} className="overflow-hidden">
                      <HistoryCard item={item} />
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
