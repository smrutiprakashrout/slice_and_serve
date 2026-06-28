"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import Image from "next/image";
import {
  Clock,
  ChefHat,
  CheckCircle2,
  Utensils,
  Package,
  History,
  ReceiptText,
  Star,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

// ─── Types ────────────────────────────────────────────────────────────────────

type OrderStatus = "pending" | "preparing" | "ready" | "served";
type ItemType = "veg" | "nonveg";

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
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

const INITIAL_ORDERS: OrderItem[] = [
  {
    id: "item-1",
    orderId: "SNS-0041",
    name: "Chicken 65 Sandwich",
    image: "/images/chilli_chicken_sand.jpg",
    price: 120,
    quantity: 2,
    status: "ready",
    type: "nonveg",
    placedAt: "10:32 AM",
  },
  {
    id: "item-2",
    orderId: "SNS-0041",
    name: "Blue Angel Drink",
    image: "/images/drink/blue_angel.jpg",
    price: 60,
    quantity: 1,
    status: "ready",
    type: "veg",
    placedAt: "10:32 AM",
  },
  {
    id: "item-3",
    orderId: "SNS-0042",
    name: "Paneer Sandwich",
    image: "/images/Panner_sandwitch.jpg",
    price: 90,
    quantity: 1,
    status: "preparing",
    type: "veg",
    placedAt: "10:41 AM",
  },
  {
    id: "item-4",
    orderId: "SNS-0043",
    name: "Chilli Mushroom Sandwich",
    image: "/images/Chilli_mushroom_sand.jpg",
    price: 95,
    quantity: 2,
    status: "pending",
    type: "veg",
    placedAt: "10:48 AM",
  },
  {
    id: "item-5",
    orderId: "SNS-0043",
    name: "Lemon Iced Tea",
    image: "/images/drink/lemon_ice_tea.jpg",
    price: 50,
    quantity: 2,
    status: "pending",
    type: "veg",
    placedAt: "10:48 AM",
  },
];

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
  preparing: {
    label: "Preparing",
    icon: ChefHat,
    step: 2,
    color: "text-blue-600",
    bg: "bg-blue-50 border-blue-200",
    pulse: false,
  },
  ready: {
    label: "Ready!",
    icon: CheckCircle2,
    step: 3,
    color: "text-green-600",
    bg: "bg-green-50 border-green-200",
    pulse: true,
  },
  served: {
    label: "Served",
    icon: Utensils,
    step: 4,
    color: "text-gray-400",
    bg: "bg-gray-50 border-gray-200",
    pulse: false,
  },
};

const STEPS: { key: OrderStatus; label: string }[] = [
  { key: "pending", label: "Placed" },
  { key: "preparing", label: "Cooking" },
  { key: "ready", label: "Ready" },
  { key: "served", label: "Served" },
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
                      ? active && status === "ready"
                        ? "bg-green-700 border-green-700 shadow-md"
                        : "bg-[#c17f24] border-[#c17f24]"
                      : "bg-white border-gray-200"
                  }`}
              >
                {done && (
                  <div
                    className={`w-2 h-2 rounded-full ${active && status === "ready" ? "bg-white" : "bg-white"}`}
                  />
                )}
              </div>
              <p
                className={`text-[8px] font-bold leading-none whitespace-nowrap
                ${done ? (active && status === "ready" ? "text-green-600" : "text-[#c17f24]") : "text-gray-300"}`}
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
  onMarkServed,
}: {
  item: OrderItem;
  onMarkServed: (id: string) => void;
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

        {/* Ready CTA */}
        {item.status === "ready" && (
          <button
            onClick={() => onMarkServed(item.id)}
            className="mt-4 w-full h-11 bg-yellow-500 text-white font-black text-xs rounded-xl flex items-center justify-center gap-2 active:scale-95 transition-transform"
          >
            <Utensils className="w-4 h-4" />
            Mark as Served &amp; Complete
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
          <div className="flex items-center gap-1 bg-gray-100 rounded-full px-2.5 py-1">
            <CheckCircle2 className="w-3 h-3 text-gray-400" strokeWidth={2.5} />
            <p className="text-[10px] font-black text-gray-400">Served</p>
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

// ─── Group orders by order ID ─────────────────────────────────────────────────

const groupBy = (items: OrderItem[]) => {
  const groups: Record<string, OrderItem[]> = {};
  items.forEach((item) => {
    if (!groups[item.orderId]) groups[item.orderId] = [];
    groups[item.orderId].push(item);
  });
  return groups;
};

// ─── Main Page ─────────────────────────────────────────────────────────────────

export default function OrdersPage() {
  const [activeTab, setActiveTab] = useState<"active" | "history">("active");
  const [orders, setOrders] = useState<OrderItem[]>(INITIAL_ORDERS);
  const [history, setHistory] = useState<OrderItem[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);

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

      // Pulse animation for "ready" cards
      gsap.to(".ready-pulse", {
        boxShadow: "0 0 0 6px rgba(34,197,94,0.15)",
        duration: 1.2,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
      });
    },
    { scope: containerRef, dependencies: [activeTab] },
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

  const handleMarkServed = (id: string) => {
    const target = orders.find((o) => o.id === id);
    if (!target) return;

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
        onComplete: () => {
          const servedItem = { ...target, status: "served" as OrderStatus };
          setOrders((prev) => prev.filter((o) => o.id !== id));
          setHistory((prev) => [servedItem, ...prev]);
        },
      });
    } else {
      const servedItem = { ...target, status: "served" as OrderStatus };
      setOrders((prev) => prev.filter((o) => o.id !== id));
      setHistory((prev) => [servedItem, ...prev]);
    }
  };

  // Separate active orders by status section
  const pending = orders.filter((o) => o.status === "pending");
  const preparing = orders.filter((o) => o.status === "preparing");
  const ready = orders.filter((o) => o.status === "ready");

  return (
    <div
      ref={containerRef}
      className="bg-[#fff1e3] min-h-dvh font-sans text-[#3d1a00]"
    >
      <style>{`
        @keyframes ready-ring {
          0%, 100% { box-shadow: 0 0 0 0 rgba(34,197,94,0.25); }
          50%       { box-shadow: 0 0 0 8px rgba(34,197,94,0); }
        }
        .ready-ring { animation: ready-ring 2s ease-in-out infinite; }
      `}</style>

      {/* ── Page Header ──────────────────────────────────────────── */}
      <div className="px-5 pb-3 pt-28">
        <h1 className="text-2xl font-black text-[#3d1a00] leading-tight">
          My Orders
        </h1>
        <p className="text-xs text-[#3d1a00]/50 mt-0.5">
          {orders.length > 0
            ? `${orders.length} active item${orders.length !== 1 ? "s" : ""} · tap "Mark as Served" when collected`
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
                  {orders.length > 0 && (
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
                  {history.length > 0 && (
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

      {/* ── Active Tab ───────────────────────────────────────────── */}
      {activeTab === "active" && (
        <div className="px-5 pb-28">
          {orders.length === 0 ? (
            <EmptyActive />
          ) : (
            <div className="space-y-6">
              {/* Ready section */}
              {ready.length > 0 && (
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-2 h-2 bg-green-800 rounded-full animate-pulse" />
                    <p className="text-[10px] font-black tracking-widest uppercase text-green-700">
                      Ready to Collect ({ready.length})
                    </p>
                  </div>
                  <div className="space-y-3">
                    {ready.map((item) => (
                      <div
                        key={item.id}
                        id={`order-card-${item.id}`}
                        className="overflow-hidden"
                      >
                        <OrderCard
                          item={item}
                          onMarkServed={handleMarkServed}
                        />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Preparing section */}
              {preparing.length > 0 && (
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <ChefHat className="w-3.5 h-3.5 text-blue-500" />
                    <p className="text-[10px] font-black tracking-widest uppercase text-blue-700">
                      Being Prepared ({preparing.length})
                    </p>
                  </div>
                  <div className="space-y-3">
                    {preparing.map((item) => (
                      <div
                        key={item.id}
                        id={`order-card-${item.id}`}
                        className="overflow-hidden"
                      >
                        <OrderCard
                          item={item}
                          onMarkServed={handleMarkServed}
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
                          onMarkServed={handleMarkServed}
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
                    ₹{history.reduce((sum, o) => sum + o.price * o.quantity, 0)}
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
    </div>
  );
}
