"use client";

import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  X,
  Info,
  CheckCircle2,
  ShoppingBag,
  Plus,
  Minus,
  ArrowRight,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

// ─── Types ────────────────────────────────────────────────────────────────────

type ItemType = "veg" | "nonveg";

interface CartItem {
  id: string;
  name: string;
  image: string;
  price: number;
  qty: number;
  type: ItemType;
}

// ─── Mock cart data ───────────────────────────────────────────────────────────

const INITIAL_CART: CartItem[] = [
  {
    id: "c1",
    name: "Chicken 65 Sandwich",
    image: "/images/chilli_chicken_sand.jpg",
    price: 120,
    qty: 1,
    type: "nonveg",
  },
  {
    id: "c2",
    name: "Paneer Sandwich",
    image: "/images/Panner_sandwitch.jpg",
    price: 90,
    qty: 2,
    type: "veg",
  },
  {
    id: "c3",
    name: "Lemon Iced Tea",
    image: "/images/drink/lemon_ice_tea.jpg",
    price: 50,
    qty: 1,
    type: "veg",
  },
];

const PROMO_CODES: Record<string, number> = {
  SLICE10: 10,
  SERVE20: 20,
  WELCOME: 15,
};

const DELIVERY_FEE = 20;

// ─── Veg / Non-veg dot badge ──────────────────────────────────────────────────

function VegDot({ type }: { type: ItemType }) {
  return (
    <div
      className={`w-4 h-4 border-2 rounded-[3px] flex items-center justify-center shrink-0
        ${type === "veg" ? "border-green-600" : "border-red-500"}`}
    >
      <div
        className={`w-2 h-2 rounded-full ${type === "veg" ? "bg-green-600" : "bg-red-500"}`}
      />
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function CartPage() {
  const router = useRouter();
  const containerRef = useRef<HTMLDivElement>(null);

  const [cart, setCart] = useState<CartItem[]>(INITIAL_CART);
  const [promoInput, setPromoInput] = useState("");
  const [appliedPromo, setAppliedPromo] = useState<string | null>(null);
  const [promoError, setPromoError] = useState(false);
  const [promoSuccess, setPromoSuccess] = useState(false);

  // ── Entrance animations ──
  useGSAP(
    () => {
      const tl = gsap.timeline();
      tl.from(".cart-header", {
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

  // ── Cart operations ──
  const updateQty = (id: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) =>
          item.id === id ? { ...item, qty: item.qty + delta } : item,
        )
        .filter((item) => item.qty > 0),
    );
  };

  const removeItem = (id: string) => {
    const el = document.getElementById(`cart-item-${id}`);
    if (el) {
      gsap.to(el, {
        x: 80,
        opacity: 0,
        height: 0,
        marginBottom: 0,
        paddingTop: 0,
        paddingBottom: 0,
        duration: 0.35,
        ease: "power2.in",
        onComplete: () => setCart((prev) => prev.filter((i) => i.id !== id)),
      });
    } else {
      setCart((prev) => prev.filter((i) => i.id !== id));
    }
  };

  // ── Promo code ──
  const applyPromo = () => {
    const code = promoInput.trim().toUpperCase();
    if (PROMO_CODES[code]) {
      setAppliedPromo(code);
      setPromoError(false);
      setPromoSuccess(true);
      gsap.from(".promo-success", {
        scale: 0.8,
        opacity: 0,
        duration: 0.35,
        ease: "back.out(2)",
      });
    } else {
      setPromoError(true);
      setPromoSuccess(false);
      gsap.to(".promo-input-wrap", {
        x: [-6, 6, -5, 5, 0],
        duration: 0.35,
        ease: "none",
      });
    }
  };

  const removePromo = () => {
    setAppliedPromo(null);
    setPromoInput("");
    setPromoSuccess(false);
    setPromoError(false);
  };

  // ── Totals ──
  const itemTotal = cart.reduce((s, i) => s + i.price * i.qty, 0);
  const discount = appliedPromo
    ? Math.round((itemTotal * PROMO_CODES[appliedPromo]) / 100)
    : 0;
  const total = itemTotal - discount + DELIVERY_FEE;
  const totalItems = cart.reduce((s, i) => s + i.qty, 0);

  // ── Empty state ──
  if (cart.length === 0) {
    return (
      <div className="min-h-dvh bg-[#f0e6dc] flex flex-col items-center justify-center px-8 text-center">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-6 shadow-sm">
          <ShoppingBag className="w-10 h-10 text-[#a07850]" />
        </div>
        <h2 className="text-2xl font-black text-[#2a1800] mb-2">
          Your cart is empty
        </h2>
        <p className="text-sm text-[#2a1800]/50 mb-8 leading-relaxed">
          Looks like you haven't added anything yet. Head back to the menu!
        </p>
        <button
          onClick={() => router.back()}
          className="bg-[#4a7c59] text-white font-black text-sm px-8 h-13 py-4 rounded-2xl flex items-center gap-2 shadow-lg shadow-[#4a7c59]/30 active:scale-95 transition-transform"
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
      <style>{`
        :root { --green: #4a7c59; --brown: #3d1a00; --cream: #f0e6dc; }
        * { -webkit-tap-highlight-color: transparent; }
      `}</style>

      {/* ── Scrollable content ──────────────────────────────────── */}
      <div className="flex-1 overflow-y-auto px-5 pt-6 pb-6">
        {/* ── Header ── */}
        <div className="cart-header flex items-start justify-between mb-6">
          <div className="flex items-start gap-2">
            <h1 className="text-2xl font-black text-[#2a1800] leading-tight tracking-tight">
              My Cart
            </h1>
            {/* Item count badge */}
            <span className="w-6 h-6 bg-yellow-900 text-white text-xs font-black rounded-full flex items-center justify-center mt-1 shadow-sm">
              {totalItems}
            </span>
          </div>
          <button
            onClick={() => router.back()}
            className="w-9 h-9 bg-white rounded-full flex items-center justify-center shadow-sm border border-[#e8d9cc] active:scale-95 transition-transform mt-0.5"
          >
            <X className="w-4 h-4 text-[#2a1800]/60" strokeWidth={2.5} />
          </button>
        </div>

        {/* ── Cart Items ── */}
        <div className="space-y-3 mb-6">
          {cart.map((item) => (
            <div
              key={item.id}
              id={`cart-item-${item.id}`}
              className="cart-item bg-white rounded-[20px] overflow-hidden shadow-sm"
              style={{ boxShadow: "0 2px 12px rgba(42,24,0,0.07)" }}
            >
              <div className="flex">
                {/* Image — bleeds to left edge */}
                <div className="w-24 h-28 shrink-0 relative overflow-hidden bg-[#f5e6d0]">
                  <img
                    src={item.image}
                    alt={item.name}
                    className="w-full h-full object-cover"
                  />
                </div>

                {/* Info */}
                <div className="flex-1 px-4 py-3 flex flex-col justify-between min-w-0">
                  <div>
                    {/* Veg dot + name */}
                    <div className="flex items-center gap-1.5 mb-1">
                      <VegDot type={item.type} />
                      <p className="font-black text-[#2a1800] text-sm leading-tight line-clamp-1">
                        {item.name}
                      </p>
                    </div>
                    {/* Price */}
                    <p className="text-[#4a7c59] pt-4 font-black text-base leading-none">
                      ₹{item.price}
                    </p>
                  </div>

                  {/* Qty stepper */}
                  <div className="flex items-center justify-end gap-3 mt-2">
                    <button
                      onClick={() => updateQty(item.id, -1)}
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
                      onClick={() => updateQty(item.id, 1)}
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
              <div className="px-4 py-2 bg-[#faf7f4] border-t border-[#f0e6dc] flex justify-between items-center">
                <p className="text-[11px] text-[#2a1800]/40 font-semibold">
                  {item.qty} × ₹{item.price}
                </p>
                <div className="flex items-center gap-3">
                  <p className="text-xs font-black text-[#2a1800]">
                    ₹{item.price * item.qty}
                  </p>
                  <button
                    onClick={() => removeItem(item.id)}
                    className="text-[10px] text-red-400 font-bold active:text-red-600"
                  >
                    Remove
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* ── Promo Code ── */}
        <div className="promo-section mb-6">
          <p className="text-base font-black text-[#2a1800] mb-3">
            Have a promo code?
          </p>

          {appliedPromo ? (
            <div className="promo-success bg-white rounded-2xl px-4 py-3.5 flex items-center justify-between shadow-sm border border-green-100">
              <div className="flex items-center gap-2">
                <CheckCircle2
                  className="w-5 h-5 text-[#4a7c59] fill-green-50"
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
                className="text-[11px] text-red-400 font-bold active:text-red-600"
              >
                Remove
              </button>
            </div>
          ) : (
            <div
              className="promo-input-wrap bg-white rounded-2xl flex items-center gap-2 px-4 shadow-sm overflow-hidden"
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
                className="flex-1 py-3.5 bg-transparent text-sm font-black text-[#4a7c59] placeholder:text-[#2a1800]/20 outline-none tracking-widest"
              />
              {promoError && (
                <p className="text-[10px] text-red-400 font-bold whitespace-nowrap">
                  Invalid
                </p>
              )}
              <button
                onClick={applyPromo}
                className="bg-yellow-900 text-white font-black text-xs px-5 py-2.5 rounded-xl shadow-sm active:scale-95 transition-transform whitespace-nowrap"
              >
                Apply
              </button>
            </div>
          )}

          {/* Hint */}
          {!appliedPromo && (
            <p className="text-[10px] text-[#2a1800]/35 mt-2 px-1 font-medium">
              Try: SLICE10 · SERVE20 · WELCOME
            </p>
          )}
        </div>

        {/* ── Order Summary ── */}
        <div
          className="summary-section bg-white rounded-[20px] overflow-hidden mb-6"
          style={{ boxShadow: "0 2px 12px rgba(42,24,0,0.07)" }}
        >
          <div className="px-5 pt-5 pb-4">
            <p className="text-base font-black text-[#2a1800] mb-4">
              Order summary
            </p>

            <div className="space-y-3">
              {/* Item total */}
              <div className="flex justify-between items-center">
                <p className="text-sm text-[#2a1800]/50 font-medium">
                  Item total
                </p>
                <p className="text-sm font-black text-[#2a1800]">
                  ₹{itemTotal}
                </p>
              </div>

              {/* Discount row */}
              {appliedPromo && (
                <div className="flex justify-between items-center">
                  <p className="text-sm text-[#4a7c59] font-medium">
                    Promo ({appliedPromo})
                  </p>
                  <p className="text-sm font-black text-[#4a7c59]">
                    −₹{discount}
                  </p>
                </div>
              )}

              {/* Delivery fee */}
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-1.5">
                  <p className="text-sm text-[#2a1800]/50 font-medium">
                    Delivery fee
                  </p>
                  <Info
                    className="w-3.5 h-3.5 text-[#2a1800]/30"
                    strokeWidth={2}
                  />
                </div>
                <p className="text-sm font-black text-[#2a1800]">
                  ₹{DELIVERY_FEE}
                </p>
              </div>
            </div>

            {/* Divider */}
            <div className="my-4 h-px bg-[#f0e6dc]" />

            {/* Total */}
            <div className="flex justify-between items-center">
              <p className="text-base font-black text-[#2a1800]">Total</p>
              <p className="text-xl font-black text-[#2a1800]">₹{total}</p>
            </div>
          </div>

          {/* Savings callout */}
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

      {/* ── Sticky Checkout ─────────────────────────────────────── */}
      <div
        className="checkout-btn px-5 pb-8 pt-3 bg-[#f0e6dc]"
        style={{ boxShadow: "0 -8px 24px rgba(42,24,0,0.06)" }}
      >
        {/* Mini summary above button */}
        <div className="flex justify-between items-center mb-3 px-1">
          <p className="text-xs text-[#2a1800]/40 font-semibold">
            {totalItems} item{totalItems !== 1 ? "s" : ""} in cart
          </p>
          <p className="text-xs text-[#2a1800]/40 font-semibold">
            Total: <span className="text-[#2a1800] font-black">₹{total}</span>
          </p>
        </div>

        <button
          className="w-full h-14 bg-yellow-900 text-white font-black text-base rounded-2xl flex items-center justify-center gap-3 shadow-xl shadow-[#4a7c59]/30 active:scale-[0.98] transition-transform"
          onClick={() => {
            // Wire to checkout flow
            gsap.to(".checkout-btn button", {
              scale: 0.97,
              duration: 0.1,
              yoyo: true,
              repeat: 1,
            });
          }}
        >
          Check Out
          <span className="bg-white/20 rounded-lg px-2.5 py-0.5 text-sm font-black">
            ₹{total}
          </span>
        </button>
      </div>
    </div>
  );
}
