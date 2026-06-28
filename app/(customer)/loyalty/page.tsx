"use client";

import { useState } from "react";
import Image from "next/image";
import {
  Gift,
  CheckCircle2,
  X,
  QrCode,
  Sparkles,
  ChevronRight,
  RefreshCw,
  PartyPopper,
} from "lucide-react";

// ─── Types ───────────────────────────────────────────────────────────────────
interface LoyaltyData {
  stamps: number;
  totalRequired: number;
  reward: {
    title: string;
    subtitle: string;
    image: string;
  };
  brand: {
    name: string;
    tagline: string;
    logo: string;
  };
}

// ─── Mock Data ────────────────────────────────────────────────────────────────
const LOYALTY: LoyaltyData = {
  stamps: 2,
  totalRequired: 6,
  reward: {
    title: "Free sandwitch of your choice",
    subtitle: "Any sandwich from the menu",
    image: "/images/65_sandwitch.jpg",
  },
  brand: {
    name: "Slice and Serve",
    tagline: "LOYALTY MEMBER ✓",
    logo: "/images/logo.png",
  },
};

// ─── Stamp Component ──────────────────────────────────────────────────────────
function Stamp({
  filled,
  index,
  animateIn,
  size,
}: {
  filled: boolean;
  index: number;
  animateIn: boolean;
  size: "sm" | "md";
}) {
  const dim = size === "sm" ? "w-11 h-11" : "w-14 h-14";
  const logoSize = size === "sm" ? "w-7 h-7" : "w-9 h-9";

  return (
    <div
      className="flex items-center justify-center"
      style={{ animationDelay: `${index * 80}ms` }}
    >
      <div
        className={`
          ${dim} rounded-full flex items-center justify-center overflow-hidden
          transition-all duration-500 ease-out
          ${
            filled
              ? "bg-yellow-900 shadow-lg shadow-yellow-900/30 scale-100"
              : "border-[2.5px] border-dashed border-[#c9a87c] bg-[#fde8cc]/40"
          }
          ${animateIn && filled ? "animate-stamp" : ""}
        `}
      >
        <img
          src="/logo.svg"
          alt="stamp"
          className={`
            ${logoSize} object-contain
            transition-all duration-500 -rotate-45
            ${filled ? "opacity-100 brightness-0 invert" : "opacity-20"}
          `}
        />
      </div>
    </div>
  );
}

// ─── Smart Stamp Grid ─────────────────────────────────────────────────────────
function StampGrid({
  total,
  stamps,
  newStampIndex,
}: {
  total: number;
  stamps: number;
  newStampIndex: number | null;
}) {
  const useGrid = total > 5;
  const cols = useGrid ? Math.ceil(total / 2) : total;
  const stampSize: "sm" | "md" = useGrid ? "sm" : "md";

  return (
    <div
      className="grid gap-x-2 gap-y-5 w-full"
      style={{ gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))` }}
    >
      {Array.from({ length: total }).map((_, i) => (
        <Stamp
          key={i}
          index={i}
          filled={i < stamps}
          animateIn={i === newStampIndex}
          size={stampSize}
        />
      ))}
    </div>
  );
}

// ─── QR Code Grid (shared) ────────────────────────────────────────────────────
const QR_GRID = [
  [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1],
  [0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0],
  [1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1],
  [0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0],
  [1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
  [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0],
  [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0],
  [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1],
];

// ─── Small QR (stamp section) ─────────────────────────────────────────────────
function QRCodeDisplay({ value }: { value: string }) {
  return (
    <div className="flex flex-col items-center gap-2">
      <div className="bg-white p-3 rounded-2xl shadow-inner border border-[#f0d9b5]">
        <div
          className="grid gap-[1.5px]"
          style={{ gridTemplateColumns: `repeat(21, 1fr)`, width: 147 }}
        >
          {QR_GRID.flat().map((cell, i) => (
            <div
              key={i}
              className="aspect-square rounded-[1px]"
              style={{ backgroundColor: cell ? "#8B1A1A" : "transparent" }}
            />
          ))}
        </div>
      </div>
      <p className="text-[10px] text-[#a07850] font-medium tracking-wider uppercase">
        Show this to staff · {value}
      </p>
    </div>
  );
}

// ─── Large QR (redeem modal) ──────────────────────────────────────────────────
function RedeemQRCode({ value }: { value: string }) {
  return (
    <div className="flex flex-col items-center gap-3">
      {/* Outer glow ring */}
      <div className="p-1 rounded-3xl bg-gradient-to-br from-yellow-900/20 to-yellow-700/10">
        <div className="bg-white p-4 rounded-2xl shadow-xl border-2 border-yellow-900/10">
          {/* Logo watermark centred over QR */}
          <div className="relative">
            <div
              className="grid gap-[2px]"
              style={{ gridTemplateColumns: `repeat(21, 1fr)`, width: 196 }}
            >
              {QR_GRID.flat().map((cell, i) => (
                <div
                  key={i}
                  className="aspect-square rounded-[1.5px]"
                  style={{ backgroundColor: cell ? "#5c3208" : "transparent" }}
                />
              ))}
            </div>
            {/* Centre logo badge */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="w-10 h-10 bg-white rounded-xl shadow-md flex items-center justify-center border-2 border-yellow-900/20">
                <img
                  src="/logo.svg"
                  alt="logo"
                  className="w-7 h-7 object-contain"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="text-center">
        <p className="text-xs font-black text-yellow-900 tracking-widest uppercase">
          Scan to Redeem
        </p>
        <p className="text-[10px] text-gray-400 mt-0.5 font-mono">{value}</p>
      </div>
    </div>
  );
}

// ─── Redeemed Success Screen ──────────────────────────────────────────────────
function RedeemedScreen({
  reward,
  onClose,
}: {
  reward: LoyaltyData["reward"];
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center px-6">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />
      <div className="relative bg-white rounded-3xl p-8 w-full max-w-sm text-center shadow-2xl animate-pop-in">
        {/* Confetti icon */}
        <div className="w-20 h-20 bg-yellow-900 rounded-full flex items-center justify-center mx-auto mb-5 shadow-xl shadow-yellow-900/30">
          <PartyPopper className="w-10 h-10 text-white" />
        </div>
        <h2 className="text-2xl font-black text-gray-900 mb-2">
          Reward Claimed!
        </h2>
        <p className="text-sm text-gray-500 mb-1">{reward.title}</p>
        <p className="text-xs text-gray-400 mb-7">{reward.subtitle}</p>
        <div className="h-px bg-[#f0d9b5] mb-6" />
        <p className="text-xs text-gray-400 mb-6">
          Your loyalty card has been reset. Keep collecting stamps for your next
          reward! 🎯
        </p>
        <button
          onClick={onClose}
          className="w-full h-13 py-4 bg-yellow-900 text-white font-black text-sm rounded-xl shadow-lg shadow-yellow-900/30 active:scale-95 transition-transform"
        >
          Start Fresh 🚀
        </button>
      </div>
    </div>
  );
}

// ─── Redeem Modal ──────────────────────────────────────────────────────────────
function RedeemModal({
  reward,
  onClose,
  onRedeemed,
}: {
  reward: LoyaltyData["reward"];
  onClose: () => void;
  onRedeemed: () => void; // called when admin "scans" → resets card
}) {
  return (
    <div className="fixed inset-0 z-[100] flex items-end justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"
        onClick={onClose}
      />

      {/* Sheet */}
      <div className="relative w-full max-w-md bg-white rounded-t-3xl overflow-hidden shadow-2xl animate-slide-up">
        {/* ── Dark red header ── */}
        <div className="bg-yellow-900 px-6 pt-6 pb-2 relative">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-8 h-8 rounded-full bg-white/20 flex items-center justify-center"
          >
            <X className="w-4 h-4 text-white" />
          </button>
          <p className="text-white/60 text-[11px] font-semibold tracking-widest uppercase mb-1">
            Redeem Reward
          </p>
          <h2 className="text-white text-2xl font-black leading-snug">
            Show this QR to
            <br />
            the merchant
          </h2>
          <p className="text-white/50 text-xs mt-1">
            They&apos;ll scan it to confirm — your card resets instantly
          </p>
        </div>

        {/* ── Reward label card (overlaps header) ── */}
        <div className="mx-5 -mt-16 bg-white rounded-2xl shadow-[0_4px_24px_rgba(0,0,0,0.10)] border border-[#f0d9b5] overflow-hidden">
          <div className="bg-[#fff1e3] px-4 py-2.5 flex items-center gap-2">
            <div className="w-6 h-6 bg-yellow-900 rounded-full flex items-center justify-center shrink-0">
              <Gift className="w-3 h-3 text-white" />
            </div>
            <div className="flex-1">
              <p className="text-[9px] font-black text-yellow-900 tracking-widest uppercase leading-none">
                Slice and Serve · Loyalty Reward
              </p>
              <p className="text-xs font-black text-gray-800 mt-0.5 leading-tight">
                {reward.title}
              </p>
            </div>
            <CheckCircle2
              className="w-5 h-5 text-green-500 fill-green-100 shrink-0"
              strokeWidth={2}
            />
          </div>

          {/* ── Large scannable QR ── */}
          <div className="py-6 flex justify-center bg-white">
            <RedeemQRCode value="SNS-REDEEM-00421" />
          </div>

          {/* Instruction strip */}
          <div className="bg-[#fff8f0] border-t border-[#f0d9b5] px-4 py-3 flex items-center gap-2">
            <QrCode className="w-4 h-4 text-yellow-900 shrink-0" />
            <p className="text-[11px] text-gray-600 leading-snug">
              Merchant scans this code on their admin panel to verify and redeem
              your reward.
            </p>
          </div>
        </div>

        {/* ── Simulate admin scan button (demo only — remove in production) ── */}
        <div className="mx-5 mt-4 mb-6">
          <p className="text-[9px] text-center text-gray-300 font-semibold tracking-widest uppercase mb-2">
            Demo only
          </p>
          <button
            onClick={onRedeemed}
            className="w-full h-13 py-4 bg-yellow-900 text-white font-black text-sm rounded-xl shadow-lg shadow-yellow-900/30 flex items-center justify-center gap-2 active:scale-95 transition-transform"
          >
            <CheckCircle2 className="w-5 h-5" />
            Simulate Admin Scan &amp; Redeem
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Main Page ─────────────────────────────────────────────────────────────────
export default function LoyaltyPage() {
  const [stamps, setStamps] = useState(LOYALTY.stamps);
  const [showRedeem, setShowRedeem] = useState(false);
  const [showRedeemed, setShowRedeemed] = useState(false);
  const [newStampIndex, setNewStampIndex] = useState<number | null>(null);

  const total = LOYALTY.totalRequired;
  const remaining = total - stamps;
  const complete = stamps >= total;

  const simulateStamp = () => {
    if (stamps < total) {
      setNewStampIndex(stamps);
      setStamps((s) => s + 1);
      setTimeout(() => setNewStampIndex(null), 600);
    }
  };

  // Called when admin scans the redeem QR → reset card, show success
  const handleRedeemed = () => {
    setShowRedeem(false);
    setShowRedeemed(true);
  };

  // Called on "Start Fresh" → full reset
  const handleReset = () => {
    setStamps(0);
    setShowRedeemed(false);
  };

  return (
    <>
      <style>{`
        @keyframes stamp {
          0%   { transform: scale(0.4) rotate(-15deg); opacity: 0; }
          60%  { transform: scale(1.18) rotate(4deg); opacity: 1; }
          100% { transform: scale(1) rotate(0deg); opacity: 1; }
        }
        .animate-stamp { animation: stamp 0.45s cubic-bezier(.36,.07,.19,.97) forwards; }

        @keyframes slide-up {
          from { transform: translateY(100%); }
          to   { transform: translateY(0); }
        }
        .animate-slide-up { animation: slide-up 0.38s cubic-bezier(0.32, 0.72, 0, 1) forwards; }

        @keyframes pop-in {
          0%   { transform: scale(0.85); opacity: 0; }
          70%  { transform: scale(1.04); opacity: 1; }
          100% { transform: scale(1); opacity: 1; }
        }
        .animate-pop-in { animation: pop-in 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) forwards; }

        @keyframes pulse-glow {
          0%, 100% { box-shadow: 0 0 0 0 rgba(101,67,33,0.35); }
          50%       { box-shadow: 0 0 0 10px rgba(101,67,33,0); }
        }
        .animate-pulse-glow { animation: pulse-glow 2s ease-in-out infinite; }
      `}</style>

      <main className="bg-[#fff1e3] font-sans min-h-dvh">
        <div className="max-w-md mx-auto w-full bg-[#fff1e3] min-h-dvh flex flex-col relative shadow-2xl pb-32">
          {/* ── Header ───────────────────────────────────────────────── */}
          <div className="px-6 pt-6 pb-10">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 bg-white rounded-xl flex items-center justify-center overflow-hidden shadow-inner">
                <Image
                  src={LOYALTY.brand.logo}
                  alt="logo"
                  width={36}
                  height={36}
                  className="object-contain"
                />
              </div>
              <div>
                <p className="text-black font-black text-base leading-tight">
                  {LOYALTY.brand.name}
                </p>
                <p className="text-black/60 text-[11px] font-semibold tracking-widest uppercase">
                  {LOYALTY.brand.tagline}
                </p>
              </div>
            </div>
          </div>

          {/* ── Reward Preview ───────────────────────────────────────── */}
          <div className="mx-5 -mt-5 bg-white rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.08)] border border-[#f0d9b5] flex items-center gap-4 p-4 z-10">
            <div className="w-16 h-16 rounded-xl overflow-hidden bg-[#f5e6d0] shrink-0">
              <img
                src={LOYALTY.reward.image}
                alt={LOYALTY.reward.title}
                className="w-full h-full object-cover"
              />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[10px] font-black text-[#8B1A1A] tracking-widest uppercase mb-0.5">
                {complete ? "🎉 Ready to claim!" : "Your next treat"}
              </p>
              <h3 className="font-black text-gray-900 text-sm leading-tight truncate">
                {LOYALTY.reward.title}
              </h3>
              <p className="text-[11px] text-gray-500 mt-0.5">
                {complete
                  ? "Tap 'Claim Reward' below"
                  : `Collect ${remaining} more stamp${remaining !== 1 ? "s" : ""}`}
              </p>
            </div>
            <Sparkles
              className={`w-5 h-5 shrink-0 ${complete ? "text-[#fdc647]" : "text-gray-200"}`}
            />
          </div>

          {/* ── Stamp Card ───────────────────────────────────────────── */}
          <div className="mx-5 mt-4 bg-white rounded-2xl shadow-[0_2px_12px_rgba(0,0,0,0.06)] border border-[#f0d9b5] p-5">
            <p className="text-[10px] font-black text-gray-400 tracking-widest uppercase mb-4">
              Stamp Card
            </p>

            <StampGrid
              total={total}
              stamps={stamps}
              newStampIndex={newStampIndex}
            />

            <p className="text-center text-sm text-gray-500 mt-4">
              {complete ? (
                <span className="font-bold text-yellow-900">
                  🎉 All stamps collected!
                </span>
              ) : (
                <>
                  You&apos;re{" "}
                  <span className="font-black text-yellow-900">
                    {remaining} stamp{remaining !== 1 ? "s" : ""}
                  </span>{" "}
                  away from your treat!
                </>
              )}
            </p>

            <button
              onClick={() => complete && setShowRedeem(true)}
              disabled={!complete}
              className={`
                mt-4 w-full h-14 rounded-xl flex items-center justify-center gap-2
                font-black text-sm tracking-wide transition-all duration-300
                ${
                  complete
                    ? "bg-yellow-900 text-white shadow-lg shadow-yellow-900/30 animate-pulse-glow active:scale-95"
                    : "bg-[#f5e6d0] text-[#c9a87c] cursor-not-allowed"
                }
              `}
            >
              <Gift className="w-5 h-5" />
              Claim Reward
            </button>
          </div>

          {/* ── QR Code Section ──────────────────────────────────────── */}
          <div className="mx-5 mt-4 bg-white rounded-2xl shadow-[0_2px_12px_rgba(0,0,0,0.06)] border border-[#f0d9b5] p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <p className="text-[10px] font-black text-gray-400 tracking-widest uppercase">
                  Your QR Code
                </p>
                <p className="text-xs text-gray-500 mt-0.5">
                  Show to staff — they&apos;ll add your stamp
                </p>
              </div>
              <QrCode className="w-5 h-5 text-yellow-900" />
            </div>

            <QRCodeDisplay value="SNS-CUST-00421" />

            <div className="mt-4 bg-[#fff1e3] rounded-xl p-3 flex gap-3 items-start">
              <div className="w-6 h-6 bg-yellow-900 rounded-full flex items-center justify-center shrink-0 mt-0.5">
                <span className="text-white text-[10px] font-black">?</span>
              </div>
              <div>
                <p className="text-xs font-bold text-gray-800 leading-tight">
                  How stamps work
                </p>
                <p className="text-[11px] text-gray-500 mt-0.5 leading-relaxed">
                  After each purchase, show this QR to the staff. They scan it
                  on their admin device and your stamp appears here instantly —
                  no paper card needed.
                </p>
              </div>
            </div>
          </div>

          {/* ── Demo Controls ─────────────────────────────────────────── */}
          <div className="mx-5 mt-4 border-2 border-dashed border-[#f0d9b5] rounded-2xl p-4 flex items-center justify-between">
            <div>
              <p className="text-[10px] font-black text-[#c9a87c] tracking-widest uppercase">
                Demo Controls
              </p>
              <p className="text-xs text-gray-400 mt-0.5">
                Simulate stamp being added by admin
              </p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleReset}
                className="w-10 h-10 rounded-xl bg-[#f5e6d0] flex items-center justify-center active:scale-95 transition-transform"
              >
                <RefreshCw className="w-4 h-4 text-yellow-900" />
              </button>
              <button
                onClick={simulateStamp}
                disabled={complete}
                className={`
                  flex items-center gap-2 px-4 h-10 rounded-xl font-bold text-xs transition-all active:scale-95
                  ${complete ? "bg-gray-100 text-gray-400 cursor-not-allowed" : "bg-yellow-900 text-white shadow-md shadow-yellow-900/30"}
                `}
              >
                + Add Stamp
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* ── Redeem Modal ─────────────────────────────────────────────── */}
      {showRedeem && (
        <RedeemModal
          reward={LOYALTY.reward}
          onClose={() => setShowRedeem(false)}
          onRedeemed={handleRedeemed}
        />
      )}

      {/* ── Redeemed Success Overlay ─────────────────────────────────── */}
      {showRedeemed && (
        <RedeemedScreen reward={LOYALTY.reward} onClose={handleReset} />
      )}
    </>
  );
}
