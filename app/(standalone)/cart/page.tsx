"use client";

import { useRef, useState } from "react";

import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  X,
  CheckCircle2,
  ShoppingBag,
  ShoppingCart,
  Plus,
  Minus,
  ArrowRight,
  Utensils,
  Clock,
  AlertCircle,
} from "lucide-react";
import { useCartStore } from "@/lib/cart-store";

gsap.registerPlugin(useGSAP);

const PROMO_CODES: Record<string, number> = {
  SLICE10: 10,
  SERVE20: 20,
  WELCOME: 15,
};

function VegDot({ type }: { type: "veg" | "nonveg" }) {
  return (
    <div
      className={`w-4 h-4 border-2 rounded-[3px] flex items-center justify-center shrink-0 ${type === "veg" ? "border-green-600" : "border-red-500"}`}
    >
      <div
        className={`w-2 h-2 rounded-full ${type === "veg" ? "bg-green-600" : "bg-red-500"}`}
      />
    </div>
  );
}

// ─── Fulfillment Choice Modal ─────────────────────────────────────────────────
function FulfillmentModal({
  fulfillment,
  setFulfillment,
  tableNumber,
  setTableNumber,
  total,
  isSubmitting,
  error,
  onClose,
  onConfirm,
}: {
  fulfillment: "dine-in" | "pickup";
  setFulfillment: (val: "dine-in" | "pickup") => void;
  tableNumber: string;
  setTableNumber: (val: string) => void;
  total: number;
  isSubmitting: boolean;
  error?: string | null;
  onClose: () => void;
  onConfirm: () => void;
}) {
  const modalRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    gsap.from(modalRef.current, {
      y: 40,
      opacity: 0,
      duration: 0.25,
      ease: "power2.out",
    });
  });

  return (
    <div className="fixed inset-0 z-[200] flex items-end sm:items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"
        onClick={isSubmitting ? undefined : onClose}
      />

      {/* Modal / Sheet */}
      <div
        ref={modalRef}
        className="relative w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl border border-[#f0d9b5]"
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-black text-xl text-[#2a1800]">
              Choose Fulfillment
            </h3>
            <p className="text-xs text-[#2a1800]/50 mt-0.5">
              How would you like to receive your order?
            </p>
          </div>
          <button
            type="button"
            disabled={isSubmitting}
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[#f0e6dc] disabled:opacity-50 flex items-center justify-center text-[#2a1800]/70 hover:text-[#2a1800] active:scale-95 transition-transform"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Error banner if any */}
        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 rounded-2xl p-3.5 flex items-start gap-2.5 text-left">
            <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
            <div className="flex-1 min-w-0">
              <p className="text-xs text-red-700 font-bold">Item Unavailable</p>
              <p className="text-[11px] text-red-600 font-medium mt-0.5 leading-relaxed">
                {error}
              </p>
            </div>
          </div>
        )}

        {/* Two Choices: Dine-in and Pickup */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => setFulfillment("dine-in")}
            className={`p-3.5 rounded-2xl border-2 flex flex-col items-center gap-2 transition-all active:scale-[0.98] ${
              fulfillment === "dine-in"
                ? "border-yellow-900 bg-[#fff1e3] text-yellow-950 shadow-sm"
                : "border-[#e8d9cc] bg-[#f0e6dc]/30 text-[#2a1800]/60 hover:border-[#d8c8b8]"
            } ${isSubmitting ? "opacity-60 cursor-not-allowed" : ""}`}
          >
            <div
              className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                fulfillment === "dine-in"
                  ? "bg-yellow-900 text-white"
                  : "bg-[#f0e6dc] text-[#2a1800]"
              }`}
            >
              <Utensils className="w-4 h-4" />
            </div>
            <div className="text-center">
              <p className="text-xs font-black">Dine-in</p>
              <p className="text-[10px] text-[#2a1800]/45 font-medium">
                Eat at the café
              </p>
            </div>
          </button>

          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => setFulfillment("pickup")}
            className={`p-3.5 rounded-2xl border-2 flex flex-col items-center gap-2 transition-all active:scale-[0.98] ${
              fulfillment === "pickup"
                ? "border-yellow-900 bg-[#fff1e3] text-yellow-950 shadow-sm"
                : "border-[#e8d9cc] bg-[#f0e6dc]/30 text-[#2a1800]/60 hover:border-[#d8c8b8]"
            } ${isSubmitting ? "opacity-60 cursor-not-allowed" : ""}`}
          >
            <div
              className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                fulfillment === "pickup"
                  ? "bg-yellow-900 text-white"
                  : "bg-[#f0e6dc] text-[#2a1800]"
              }`}
            >
              <ShoppingBag className="w-4 h-4" />
            </div>
            <div className="text-center">
              <p className="text-xs font-black">Pickup</p>
              <p className="text-[10px] text-[#2a1800]/45 font-medium">
                Takeaway counter
              </p>
            </div>
          </button>
        </div>

        {/* Conditional content */}
        {fulfillment === "dine-in" ? (
          <div className="mb-6 bg-[#f0e6dc]/30 border border-[#e8d9cc] rounded-2xl p-3.5">
            <label className="block text-xs font-bold text-[#2a1800]/70 mb-1.5">
              Table number (optional)
            </label>
            <div className="bg-white border border-[#e8d9cc] rounded-xl flex items-center px-3.5 focus-within:border-yellow-900 transition-colors">
              <input
                type="text"
                disabled={isSubmitting}
                value={tableNumber}
                onChange={(e) => setTableNumber(e.target.value)}
                placeholder="Table number (optional)"
                className="w-full py-2.5 bg-transparent text-sm font-black text-[#2a1800] placeholder:text-[#2a1800]/25 outline-none disabled:opacity-60"
              />
            </div>
            <p className="text-[11px] text-[#2a1800]/40 mt-1.5 font-medium">
              Leave blank if ordering before finding a seat
            </p>
          </div>
        ) : (
          <div className="mb-6 bg-[#f0e6dc]/30 border border-[#e8d9cc] rounded-xl p-3.5 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-yellow-900/10 flex items-center justify-center shrink-0">
              <Clock className="w-4 h-4 text-yellow-900" />
            </div>
            <div>
              <p className="text-xs font-black text-[#2a1800]">
                Ready in about 15–20 minutes
              </p>
              <p className="text-[11px] text-[#2a1800]/50 font-medium">
                Collect at the counter with your order number
              </p>
            </div>
          </div>
        )}

        {/* Confirm and Cancel actions */}
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onConfirm}
          className="w-full h-12 bg-yellow-900 disabled:opacity-60 disabled:cursor-not-allowed text-white font-black text-sm rounded-xl flex items-center justify-center gap-2 shadow-lg active:scale-[0.98] transition-transform mb-2.5 cursor-pointer"
        >
          {isSubmitting ? (
            <>
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              Placing order...
            </>
          ) : (
            <>
              <CheckCircle2 className="w-4 h-4" />
              Confirm Order · ₹{total}
            </>
          )}
        </button>
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onClose}
          className="w-full h-11 bg-[#f0e6dc] disabled:opacity-60 text-[#2a1800] font-black text-xs rounded-xl active:scale-[0.98] transition-transform cursor-pointer"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}

export default function CartPage() {
  const router = useRouter();
  const containerRef = useRef<HTMLDivElement>(null);

  // ── All prices come from the store — populated by the menu's addItem() ──
  const items = useCartStore((s) => s.items);
  const addItem = useCartStore((s) => s.addItem);
  const removeOne = useCartStore((s) => s.removeOne);
  const removeAll = useCartStore((s) => s.removeAll);
  const clearCart = useCartStore((s) => s.clearCart);

  const [showFulfillmentModal, setShowFulfillmentModal] = useState(false);
  const [fulfillment, setFulfillment] = useState<"dine-in" | "pickup">("dine-in");
  const [tableNumber, setTableNumber] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [promoInput, setPromoInput] = useState("");
  const [appliedPromo, setAppliedPromo] = useState<string | null>(null);
  const [promoError, setPromoError] = useState(false);

  // Entrance animations
  useGSAP(
    () => {
      gsap
        .timeline()
        .from(".cart-header", {
          y: -20,
          opacity: 0,
          duration: 0.4,
          ease: "power2.out",
        })
        .from(
          ".cart-item",
          {
            y: 24,
            opacity: 0,
            duration: 0.4,
            stagger: 0.1,
            ease: "power2.out",
          },
          "-=0.2",
        )
        .from(
          ".promo-section",
          { y: 20, opacity: 0, duration: 0.35, ease: "power2.out" },
          "-=0.1",
        )
        .from(
          ".summary-section",
          { y: 20, opacity: 0, duration: 0.35, ease: "power2.out" },
          "-=0.15",
        )
        .from(
          ".checkout-btn",
          { y: 16, opacity: 0, duration: 0.3, ease: "power2.out" },
          "-=0.1",
        );
    },
    { scope: containerRef },
  );

  // Animate out then remove
  const handleRemoveAll = (id: string) => {
    const el = document.getElementById(`cart-item-${id}`);
    if (el) {
      gsap.to(el, {
        x: 80,
        opacity: 0,
        height: 0,
        marginBottom: 0,
        duration: 0.35,
        ease: "power2.in",
        onComplete: () => removeAll(id),
      });
    } else {
      removeAll(id);
    }
  };

  // Promo
  const applyPromo = () => {
    const code = promoInput.trim().toUpperCase();
    if (PROMO_CODES[code]) {
      setAppliedPromo(code);
      setPromoError(false);
      gsap.from(".promo-success", {
        scale: 0.8,
        opacity: 0,
        duration: 0.35,
        ease: "back.out(2)",
      });
    } else {
      setPromoError(true);
      const tl = gsap.timeline();
      tl.to(".promo-input-wrap", { x: -6, duration: 0.05 })
        .to(".promo-input-wrap", { x: 6, duration: 0.05 })
        .to(".promo-input-wrap", { x: -5, duration: 0.05 })
        .to(".promo-input-wrap", { x: 5, duration: 0.05 })
        .to(".promo-input-wrap", { x: 0, duration: 0.05 });
    }
  };

  const removePromo = () => {
    setAppliedPromo(null);
    setPromoInput("");
    setPromoError(false);
  };

  // Totals — computed from real store prices
  const itemTotal = items.reduce((s, i) => s + i.price * i.qty, 0);
  const discount = appliedPromo
    ? Math.round((itemTotal * PROMO_CODES[appliedPromo]) / 100)
    : 0;
  const total = itemTotal - discount;
  const totalItems = items.reduce((s, i) => s + i.qty, 0);

  const handleConfirmOrder = async () => {
    if (items.length === 0 || isSubmitting) return;

    setIsSubmitting(true);
    setSubmitError(null);

    const payload: {
      items: Array<{ menuItemId: string; quantity: number }>;
      fulfillment: "dine-in" | "pickup";
      tableNumber?: string;
    } = {
      items: items.map((i) => ({ menuItemId: i.id, quantity: i.qty })),
      fulfillment,
    };

    if (fulfillment === "dine-in" && tableNumber.trim()) {
      payload.tableNumber = tableNumber.trim();
    }

    try {
      const res = await fetch("/api/orders", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (res.status === 201) {
        clearCart();
        setShowFulfillmentModal(false);
        router.push("/orders");
        return;
      }

      const data = await res.json().catch(() => ({}));
      const errorCode = data?.error?.code;
      const errorMessage = data?.error?.message;

      if (res.status === 401) {
        await signIn("google", { callbackUrl: "/cart" });
        return;
      }

      if (res.status === 409 || errorCode === "ITEM_UNAVAILABLE") {
        setSubmitError(
          errorMessage ||
            "One or more items in your cart are no longer available. Please review your cart.",
        );
        return;
      }

      if (res.status === 400) {
        setSubmitError(
          "Something went wrong with your order details. Please review and try again.",
        );
        return;
      }

      setSubmitError(
        errorMessage || "Failed to place order. Please try again.",
      );
    } catch (err) {
      console.error("Order placement error:", err);
      setSubmitError(
        "Network error. Please check your connection and try again.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  // Empty state
  if (items.length === 0) {
    return (
      <div className="min-h-dvh bg-[#f0e6dc] flex flex-col items-center justify-center px-8 text-center">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-6 shadow-sm">
          <ShoppingBag className="w-10 h-10 text-[#a07850]" />
        </div>
        <h2 className="text-2xl font-black text-[#2a1800] mb-2">
          Your cart is empty
        </h2>
        <p className="text-sm text-[#2a1800]/50 mb-8 leading-relaxed">
          Looks like you haven&apos;t added anything yet. Head back to the menu!
        </p>
        <button
          onClick={() => router.back()}
          className="bg-yellow-900 text-white font-black text-sm px-8 py-4 rounded-2xl flex items-center gap-2 shadow-lg active:scale-95 transition-transform"
        >
          Browse Menu <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="min-h-dvh bg-[#f0e6dc] font-sans flex flex-col"
    >
      <style>{`* { -webkit-tap-highlight-color: transparent; }`}</style>

      <div className="overflow-y-auto px-5 pt-6 pb-6">
        {/* Header */}
        <div className="fixed top-0 left-0 right-0 mx-auto w-full max-w-md bg-[#f0e6dc] shadow-xs z-50 flex items-center justify-between px-6 py-2">
          {" "}
          <div className=" w-fit h-10 flex justify-center rounded-xl">
            <div className="flex items-center gap-2">
              <div className="bg-yellow-900 h-10 w-10 rounded-lg flex justify-center items-center">
                <ShoppingCart className="text-white" />
              </div>
              <h1 className="text-md font-black text-yellow-950 leading-tight tracking-tight">
                Basket
              </h1>
              <span className="w-5 h-5 bg-white text-yellow-900 text-xs font-black rounded-full flex items-center justify-center shadow-sm">
                {totalItems}
              </span>
            </div>
          </div>
          <button
            onClick={() => router.back()}
            className="w-10 h-10 bg-yellow-900 rounded-xl flex items-center justify-center shadow-sm border border-[#e8d9cc] active:scale-95 transition-transform mt-0.5"
          >
            <X className="w-4 h-4 text-white" strokeWidth={2.5} />
          </button>
        </div>

        {/* Error banner if item unavailable / checkout issue */}
        {submitError && (
          <div className="mb-4 mt-12 bg-red-50 border border-red-200 rounded-2xl p-4 flex items-start gap-3 text-left shadow-sm">
            <AlertCircle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-xs font-black text-red-700">Order Issue</p>
              <p className="text-xs text-red-600 font-medium mt-0.5 leading-relaxed">
                {submitError}
              </p>
            </div>
            <button
              type="button"
              onClick={() => setSubmitError(null)}
              className="text-red-400 hover:text-red-600 p-0.5 cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Cart Items */}
        <div className={`space-y-3 mb-6 ${submitError ? "mt-4" : "mt-12"}`}>
          {items.map((item) => (
            <div
              key={item.id}
              id={`cart-item-${item.id}`}
              className="cart-item bg-white rounded-[20px] overflow-hidden"
              style={{ boxShadow: "0 2px 12px rgba(42,24,0,0.07)" }}
            >
              <div className="flex">
                <div className="w-24 h-28 shrink-0 overflow-hidden bg-[#f5e6d0]">
                  <img
                    src={item.image}
                    alt={item.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1 px-4 py-3 flex flex-col justify-between min-w-0">
                  <div>
                    <div className="flex items-center gap-1.5 mb-1">
                      <VegDot type={item.type} />
                      <p className="font-black text-[#2a1800] text-sm leading-tight line-clamp-1">
                        {item.name}
                      </p>
                    </div>
                    {/* Price from store — exactly matches what was shown on the menu */}
                    <p className="text-yellow-900 font-black text-base leading-none pt-1">
                      ₹{item.price}
                      <span className="text-[11px] text-[#2a1800]/30 font-semibold ml-1">
                        / item
                      </span>
                    </p>
                  </div>
                  {/* Qty stepper */}
                  <div className="flex items-center justify-end gap-3 mt-2">
                    <button
                      onClick={() => removeOne(item.id)}
                      className="w-7 h-7 rounded-full bg-[#f0e6dc] flex items-center justify-center active:scale-90 transition-transform"
                    >
                      <Minus
                        className="w-3 h-3 text-[#2a1800]"
                        strokeWidth={3}
                      />
                    </button>
                    <span className="text-[#2a1800] font-black text-base w-4 text-center">
                      {item.qty}
                    </span>
                    <button
                      onClick={() =>
                        addItem({
                          id: item.id,
                          name: item.name,
                          image: item.image,
                          price: item.price,
                          type: item.type,
                        })
                      }
                      className="w-7 h-7 rounded-full bg-[#3d1a00] flex items-center justify-center shadow-sm active:scale-90 transition-transform"
                    >
                      <Plus
                        className="w-3.5 h-3.5 text-white"
                        strokeWidth={2.5}
                      />
                    </button>
                  </div>
                </div>
              </div>
              {/* Subtotal row */}
              {/*<div className="px-4 py-2 bg-[#faf7f4] border-t border-[#f0e6dc] flex justify-between items-center">
                <p className="text-[11px] text-[#2a1800]/40 font-semibold">
                  {item.qty} × ₹{item.price}
                </p>
                <div className="flex items-center gap-3">
                  <p className="text-xs font-black text-[#2a1800]">
                    ₹{item.price * item.qty}
                  </p>
                  <button
                    onClick={() => handleRemoveAll(item.id)}
                    className="text-[10px] text-red-400 font-bold active:text-red-600"
                  >
                    Remove
                  </button>
                </div>
              </div>*/}
            </div>
          ))}
        </div>

        {/* Promo Code */}
        <div className="promo-section mb-6">
          <p className="text-sm font-bold  text-gray-500 mb-3">
            Have a promo code?
          </p>
          {appliedPromo ? (
            <div className="promo-success bg-white rounded-2xl px-4 py-3.5 flex items-center justify-between shadow-sm border border-green-100">
              <div className="flex items-center gap-2">
                <CheckCircle2
                  className="w-5 h-5 text-[#4a7c59]"
                  strokeWidth={2}
                />
                <div>
                  <p className="font-black text-sm text-[#4a7c59]">
                    {appliedPromo}
                  </p>
                  <p className="text-[11px] text-[#2a1800]/40 font-medium">
                    −₹{discount} discount applied
                  </p>
                </div>
              </div>
              <button
                onClick={removePromo}
                className="text-[11px] text-red-400 font-bold"
              >
                Remove
              </button>
            </div>
          ) : (
            <div
              className="promo-input-wrap bg-white rounded-2xl flex items-center gap-2 px-4 overflow-hidden"
              style={{
                boxShadow: promoError
                  ? "0 0 0 2px #ef4444"
                  : "0 2px 12px rgba(42,24,0,0.07)",
              }}
            >
              <input
                type="text"
                value={promoInput}
                onChange={(e) => {
                  setPromoInput(e.target.value.toUpperCase());
                  setPromoError(false);
                }}
                onKeyDown={(e) => e.key === "Enter" && applyPromo()}
                placeholder="ENTER CODE"
                className="flex-1 py-3.5 bg-transparent text-sm font-black text-yellow-900 placeholder:text-[#2a1800]/20 outline-none tracking-widest"
              />
              {promoError && (
                <p className="text-[10px] text-red-400 font-bold whitespace-nowrap">
                  Invalid
                </p>
              )}
              <button
                onClick={applyPromo}
                className="bg-yellow-900 text-white font-black text-xs px-5 py-2.5 rounded-xl active:scale-95 transition-transform whitespace-nowrap"
              >
                Apply
              </button>
            </div>
          )}
          {!appliedPromo && (
            <p className="text-[10px] text-[#2a1800]/35 mt-2 px-1 font-medium">
              Try: SLICE10 · SERVE20 · WELCOME
            </p>
          )}
        </div>

        {/* Order Summary */}
        <div
          className="summary-section bg-white rounded-[20px] overflow-hidden mb-36"
          style={{ boxShadow: "0 2px 12px rgba(42,24,0,0.07)" }}
        >
          <div className="px-5 pt-5 pb-4">
            <p className="text-base font-black text-[#2a1800] mb-4">
              Order summary
            </p>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <p className="text-sm text-[#2a1800]/50 font-medium">
                  Item total
                </p>
                <p className="text-sm font-black text-[#2a1800]">
                  ₹{itemTotal}
                </p>
              </div>
              {appliedPromo && (
                <div className="flex justify-between items-center">
                  <p className="text-sm text-yellow-900 font-medium">
                    Promo ({appliedPromo})
                  </p>
                  <p className="text-sm font-black text-yellow-900">
                    −₹{discount}
                  </p>
                </div>
              )}
            </div>
            <div className="my-4 h-px bg-[#f0e6dc]" />
            <div className="flex justify-between items-center">
              <p className="text-base font-black text-[#2a1800]">Total</p>
              <p className="text-xl font-black text-[#2a1800]">₹{total}</p>
            </div>
          </div>
          {appliedPromo && (
            <div className="bg-green-50 border-t border-green-100 px-5 py-3 flex items-center gap-2">
              <CheckCircle2
                className="w-4 h-4 text-[#4a7c59]"
                strokeWidth={2}
              />
              <p className="text-xs font-black text-[#4a7c59]">
                You save ₹{discount} with {appliedPromo}!
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Sticky Checkout */}
      <div
        className="checkout-btn fixed bottom-0 w-full max-w-md px-5 pb-8 pt-3 bg-[#f0e6dc]"
        style={{ boxShadow: "0 -8px 24px rgba(42,24,0,0.06)" }}
      >
        <div className="flex justify-between items-center mb-3 px-1">
          <p className="text-xs text-[#2a1800]/40 font-semibold">
            {totalItems} item{totalItems !== 1 ? "s" : ""} in cart
          </p>
          <p className="text-xs text-[#2a1800]/40 font-semibold">
            Total: <span className="text-[#2a1800] font-black">₹{total}</span>
          </p>
        </div>
        <button
          type="button"
          disabled={items.length === 0 || isSubmitting}
          className="w-full h-12 bg-yellow-900 disabled:opacity-50 disabled:cursor-not-allowed text-white font-black text-base rounded-2xl flex items-center justify-center gap-3 shadow-xl active:scale-[0.98] transition-transform cursor-pointer"
          onClick={() => {
            if (items.length === 0 || isSubmitting) return;
            setSubmitError(null);
            gsap.to(".checkout-btn button", {
              scale: 0.97,
              duration: 0.1,
              yoyo: true,
              repeat: 1,
              onComplete: () => setShowFulfillmentModal(true),
            });
          }}
        >
          Place order
          <span className="bg-white/20 rounded-lg px-2.5 py-0.5 text-sm font-black">
            ₹{total}
          </span>
        </button>
      </div>

      {/* ── Fulfillment Choice Modal ── */}
      {showFulfillmentModal && (
        <FulfillmentModal
          fulfillment={fulfillment}
          setFulfillment={setFulfillment}
          tableNumber={tableNumber}
          setTableNumber={setTableNumber}
          total={total}
          isSubmitting={isSubmitting}
          error={submitError}
          onClose={() => {
            if (!isSubmitting) setShowFulfillmentModal(false);
          }}
          onConfirm={handleConfirmOrder}
        />
      )}
    </div>
  );
}
