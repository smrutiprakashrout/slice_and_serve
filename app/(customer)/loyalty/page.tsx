"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Image from "next/image";
import useSWR from "swr";
import { useSession, signIn } from "next-auth/react";
import { QRCodeSVG } from "qrcode.react";
import { fetcher } from "@/lib/fetcher";
import { useIsTabVisible } from "@/lib/useIsTabVisible";
import {
  Gift,
  CheckCircle2,
  X,
  QrCode,
  PartyPopper,
  LogIn,
} from "lucide-react";

const COFFEE = "#733E0A";

interface LoyaltyMeResponse {
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
  stampToken: string;
  redeemToken?: string;
}

interface LoyaltyReward {
  title: string;
  subtitle: string;
  image: string;
}

const REWARD: LoyaltyReward = {
  title: "Free sandwich of your choice",
  subtitle: "Any sandwich from the menu",
  image: "/images/65_sandwitch.jpg",
};

const BRAND = {
  logo: "/images/logo.png",
};

function Stamp({
  filled,
  index,
  animateIn,
  isLast,
  size,
}: {
  filled: boolean;
  index: number;
  animateIn: boolean;
  isLast: boolean;
  size: "sm" | "md";
}) {
  const dim = size === "sm" ? "w-11 h-11" : "w-14 h-14";
  const logoSize = size === "sm" ? "w-7 h-7" : "w-9 h-9";

  return (
    <div
      className="flex items-center justify-center"
      style={{ animationDelay: animateIn ? "0ms" : `${index * 80}ms` }}
    >
      <div
        className={`
          ${dim} rounded-full flex items-center justify-center overflow-hidden
          transition-all duration-500 ease-out
          ${
            filled
              ? "bg-[#fdc647]"
              : isLast
                ? "border-2 border-[#fdc647]"
                : "border-2 border-dashed border-[#fff1e3]/35"
          }
          ${animateIn && filled ? "animate-stamp" : ""}
        `}
      >
        {isLast ? (
          <Gift
            aria-hidden="true"
            className={`h-5 w-5 ${filled ? "text-yellow-900" : "text-[#fdc647]"}`}
            strokeWidth={1.8}
          />
        ) : (
          <span
            aria-hidden="true"
            className={`${logoSize} ${filled ? "bg-yellow-900" : "bg-[#fff1e3]/15"}`}
            style={{
              maskImage: "url('/logo.svg')",
              maskPosition: "center",
              maskRepeat: "no-repeat",
              maskSize: "contain",
              WebkitMaskImage: "url('/logo.svg')",
              WebkitMaskPosition: "center",
              WebkitMaskRepeat: "no-repeat",
              WebkitMaskSize: "contain",
            }}
          />
        )}
      </div>
    </div>
  );
}

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
      className="grid gap-x-2 gap-y-4 w-full"
      style={{ gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))` }}
    >
      {Array.from({ length: total }).map((_, index) => (
        <Stamp
          key={index}
          index={index}
          filled={index < stamps}
          animateIn={index === newStampIndex}
          isLast={index === total - 1}
          size={stampSize}
        />
      ))}
    </div>
  );
}

function QRCodeDisplay({ stampToken }: { stampToken: string }) {
  return (
    <div className="flex justify-center">
      <div className="rounded-2xl border border-[#f0d9b5] bg-white p-3">
        <QRCodeSVG
          value={stampToken}
          size={176}
          fgColor={COFFEE}
          bgColor="#ffffff"
          level="M"
          role="img"
          aria-label="Loyalty stamp code QR"
        />
      </div>
    </div>
  );
}

function RedeemQRCode({ redeemToken }: { redeemToken: string }) {
  return (
    <div className="flex justify-center">
      <div className="rounded-2xl border border-[#f0d9b5] bg-white p-4">
        <div className="relative">
          <QRCodeSVG
            value={redeemToken}
            size={196}
            fgColor={COFFEE}
            bgColor="#ffffff"
            level="H"
            role="img"
            aria-label="Loyalty reward redemption QR"
          />
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center border border-[#f0d9b5]">
              <Image
                src="/logo.svg"
                alt="Slice & Serve logo"
                width={28}
                height={28}
                className="w-7 h-7 object-contain"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function RedeemedScreen({
  reward,
  onClose,
}: {
  reward: LoyaltyReward;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center bg-yellow-900/75 px-6">
      <div className="w-full max-w-sm rounded-3xl border border-[#f0d9b5] bg-[#fff1e3] p-8 text-center shadow-2xl animate-pop-in">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-[#f5e6d0]">
          <PartyPopper className="h-8 w-8 text-yellow-900" />
        </div>
        <span className="mb-2 inline-block rounded-full bg-[#fdc647] px-3 py-1 text-xs font-bold text-yellow-900">
          Reward claimed!
        </span>
        <h3 className="font-display mt-1 text-xl font-bold text-yellow-900">
          Enjoy your
        </h3>
        <p className="font-display mt-0.5 text-lg font-bold text-yellow-900">
          {reward.title}
        </p>
        <p className="mt-3 text-sm leading-relaxed text-yellow-900/90">
          Your card has been reset to 0 stamps. Keep collecting to earn your
          next treat!
        </p>
        <button
          onClick={onClose}
          className="mt-6 w-full rounded-xl bg-yellow-900 py-3.5 text-sm font-bold text-[#fff1e3] transition-transform active:scale-95"
        >
          Start Fresh Card
        </button>
      </div>
    </div>
  );
}

function RedeemModal({
  reward,
  redeemToken,
  onClose,
}: {
  reward: LoyaltyReward;
  redeemToken: string;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-100 flex items-end justify-center">
      <div
        className="absolute inset-0 bg-yellow-900/75"
        onClick={onClose}
      />
      <div className="animate-slide-up relative w-full max-w-md overflow-hidden rounded-t-3xl border border-[#f0d9b5] bg-[#fff1e3] shadow-2xl">
        <div className="relative bg-yellow-900 px-6 pb-5 pt-6">
          <button
            onClick={onClose}
            aria-label="Close redemption details"
            className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-full bg-[#fff1e3]/15 text-[#fff1e3]"
          >
            <X className="h-5 w-5" />
          </button>
          <p className="text-xs font-semibold text-[#fff1e3]/75">
            Redeem reward
          </p>
          <h2 className="font-display mt-1 text-2xl font-bold leading-snug text-[#fff1e3]">
            Show this QR to the merchant
          </h2>
          <p className="mt-2 text-sm text-[#fff1e3]/85">
            They&apos;ll scan it to confirm — your card resets instantly.
          </p>
        </div>

        <div className="mx-5 -mt-2 overflow-hidden rounded-2xl border border-[#f0d9b5] bg-white shadow-sm">
          <div className="flex items-center gap-3 bg-[#f5e6d0] px-4 py-3">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-yellow-900 text-[#fdc647]">
              <Gift className="h-4 w-4" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-semibold text-yellow-900">
                Slice &amp; Serve · Loyalty reward
              </p>
              <p className="font-display mt-0.5 text-base font-bold leading-tight text-yellow-900">
                {reward.title}
              </p>
            </div>
            <CheckCircle2
              aria-label="Reward ready"
              className="h-5 w-5 shrink-0 text-yellow-900"
              strokeWidth={2}
            />
          </div>

          <div className="flex justify-center bg-white py-5">
            <RedeemQRCode redeemToken={redeemToken} />
          </div>

          <div className="flex items-center gap-2 border-t border-[#f0d9b5] bg-[#f5e6d0] px-4 py-3">
            <QrCode aria-hidden="true" className="h-5 w-5 shrink-0 text-yellow-900" />
            <p className="text-sm leading-snug text-yellow-900/90">
              Merchant scans this code on their admin panel to verify and redeem
              your reward.
            </p>
          </div>
        </div>
        <div className="h-6" />
      </div>
    </div>
  );
}

export default function LoyaltyPage() {
  const { data: session, status: authStatus } = useSession();
  const isSignedIn = authStatus === "authenticated";
  const isTabVisible = useIsTabVisible();

  const { data, error, isLoading, mutate } = useSWR<LoyaltyMeResponse>(
    isSignedIn ? "/api/loyalty/me" : null,
    fetcher,
    {
      refreshInterval: isTabVisible ? 5000 : 0,
      revalidateOnFocus: true,
    },
  );

  const [showRedeem, setShowRedeem] = useState(false);
  const [showRedeemed, setShowRedeemed] = useState(false);
  const [newStampIndex, setNewStampIndex] = useState<number | null>(null);
  const [openedRedeemToken, setOpenedRedeemToken] = useState("");
  const previousStamps = useRef<number | null>(null);
  const previousRewardReady = useRef<boolean | null>(null);

  const currentStamps = data?.stamps;
  const currentRewardReady = data?.rewardReady;
  const stamps = data?.stamps ?? 0;
  const total = data?.totalRequired ?? 10;
  const rewardReady = data?.rewardReady ?? false;
  const stampToken = data?.stampToken ?? "";
  const redeemToken = data?.redeemToken;
  const remaining = Math.max(0, total - stamps);
  const complete = Boolean(rewardReady || stamps >= total);
  const firstName = session?.user?.name?.trim().split(/\s+/)[0];

  const handleRedeemed = useCallback(() => {
    setShowRedeem(false);
    setShowRedeemed(true);
    void mutate();
  }, [mutate]);

  const handleReset = () => {
    setShowRedeemed(false);
    void mutate();
  };

  useEffect(() => {
    if (currentStamps === undefined) return;
    const previous = previousStamps.current;
    previousStamps.current = currentStamps;
    if (previous === null || currentStamps <= previous) return;

    let clearIndexTimer: ReturnType<typeof setTimeout> | undefined;
    const startAnimationTimer = setTimeout(() => {
      setNewStampIndex(currentStamps - 1);
      clearIndexTimer = setTimeout(() => setNewStampIndex(null), 1000);
    }, 0);

    return () => {
      clearTimeout(startAnimationTimer);
      if (clearIndexTimer) clearTimeout(clearIndexTimer);
    };
  }, [currentStamps]);

  useEffect(() => {
    if (currentRewardReady === undefined) return;
    const wasReady = previousRewardReady.current;
    previousRewardReady.current = currentRewardReady;
    if (!showRedeem || wasReady !== true || currentRewardReady) return;

    const resetTimer = setTimeout(handleRedeemed, 0);
    return () => clearTimeout(resetTimer);
  }, [currentRewardReady, handleRedeemed, showRedeem]);

  if (authStatus === "loading" || (isSignedIn && isLoading)) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] pt-16 flex items-center justify-center pb-32">
        <div
          aria-label="Loading loyalty card"
          className="h-10 w-10 animate-spin rounded-full border-4 border-yellow-900 border-t-transparent"
        />
      </div>
    );
  }

  if (!isSignedIn) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] px-8 pt-16 pb-32 flex flex-col items-center justify-center text-center">
        <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-3xl border border-[#f0d9b5] bg-white shadow-sm">
          <Gift className="h-10 w-10 text-yellow-900" />
        </div>
        <h2 className="mb-2 text-2xl font-bold text-yellow-900">
          You&apos;re not signed in
        </h2>
        <p className="mb-8 max-w-xs text-sm leading-relaxed text-yellow-900/90">
          Sign in with Google to view and track your loyalty stamps.
        </p>
        <button
          onClick={() => signIn("google", { callbackUrl: "/loyalty" })}
          className="flex h-14 w-full max-w-xs items-center justify-center gap-3 rounded-2xl bg-yellow-900 text-sm font-bold text-[#fff1e3] shadow-sm transition-transform active:scale-95"
        >
          <LogIn className="h-5 w-5" />
          Continue with Google
        </button>
      </div>
    );
  }

  if (error) {
    const is401 = (error as Error & { status?: number }).status === 401;
    return (
      <div className="min-h-dvh bg-[#fff1e3] px-8 pt-16 pb-32 flex flex-col items-center justify-center text-center">
        <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-3xl border border-[#f0d9b5] bg-white shadow-sm">
          <Gift className="h-10 w-10 text-yellow-900" />
        </div>
        <h2 className="mb-2 text-2xl font-bold text-yellow-900">
          {is401 ? "Session Expired" : "Unable to load loyalty card"}
        </h2>
        <p className="mb-8 max-w-xs text-sm leading-relaxed text-yellow-900/90">
          {is401
            ? "Your session has expired. Please sign in again."
            : error.message || "Failed to load loyalty details. Please try again."}
        </p>
        {is401 ? (
          <button
            onClick={() => signIn("google", { callbackUrl: "/loyalty" })}
            className="flex h-14 w-full max-w-xs items-center justify-center gap-3 rounded-2xl bg-yellow-900 text-sm font-bold text-[#fff1e3] transition-transform active:scale-95"
          >
            <LogIn className="h-5 w-5" />
            Sign In
          </button>
        ) : (
          <button
            onClick={() => void mutate()}
            className="flex h-14 w-full max-w-xs items-center justify-center gap-3 rounded-2xl bg-yellow-900 text-sm font-bold text-[#fff1e3] transition-transform active:scale-95"
          >
            Try Again
          </button>
        )}
      </div>
    );
  }

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;900&display=swap');
        .font-display { font-family: 'Playfair Display', Georgia, serif; }

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
          0%, 100% { box-shadow: 0 0 0 0 rgba(253,198,71,0.35); }
          50%       { box-shadow: 0 0 0 10px rgba(253,198,71,0); }
        }
        .animate-pulse-glow { animation: pulse-glow 2s ease-in-out infinite; }

        @keyframes loyalty-fade-up {
          from { opacity: 0; transform: translateY(12px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @media (prefers-reduced-motion: no-preference) {
          .loyalty-enter { animation: loyalty-fade-up 0.45s ease-out both; }
          .loyalty-enter-2 { animation-delay: 80ms; }
          .loyalty-enter-3 { animation-delay: 160ms; }
        }
        button:focus-visible {
          outline: 3px solid #fdc647;
          outline-offset: 3px;
        }
      `}</style>

      <main className="min-h-dvh bg-[#fff1e3] font-sans">
        <div className="mx-auto mt-16 flex min-h-dvh w-full max-w-md flex-col gap-4 bg-[#fff1e3] px-5 pb-32 pt-5">
          <header className="loyalty-enter flex items-center gap-3 px-1">
            <Image
              src={BRAND.logo}
              alt="Slice & Serve"
              width={42}
              height={42}
              className="h-10 w-10 object-contain"
            />
            <div className="min-w-0">
              <h1 className="font-display text-2xl font-bold leading-tight text-yellow-900">
                Loyalty Card
              </h1>
              {firstName && (
                <p className="mt-0.5 text-sm text-yellow-900/90">Hi, {firstName}</p>
              )}
            </div>
          </header>

          <section className="loyalty-enter loyalty-enter-2 relative overflow-hidden rounded-3xl bg-yellow-900 p-5 text-[#fff1e3] shadow-lg shadow-yellow-900/15">
            <div
              aria-hidden="true"
              className="pointer-events-none absolute inset-0 opacity-60"
              style={{
                backgroundImage:
                  "radial-gradient(circle at 1px 1px, rgba(255,241,227,0.10) 1px, transparent 0)",
                backgroundSize: "18px 18px",
              }}
            />
            <div className="relative">
              <p className="text-xs font-semibold text-[#fff1e3]/75">Slice &amp; Serve</p>
              <div className="mt-1 flex items-baseline gap-2">
                <span className="font-display text-5xl font-bold leading-none text-[#fff1e3]">
                  {stamps}
                </span>
                <span className="text-lg font-semibold text-[#fff1e3]/85">/ {total}</span>
              </div>
              <p className="mt-2 text-sm text-[#fff1e3]/90">
                {complete ? "stamps collected" : `${remaining} more for your free treat`}
              </p>

              <div className="my-5">
                <StampGrid
                  total={total}
                  stamps={stamps}
                  newStampIndex={newStampIndex}
                />
              </div>

              <div className="border-t border-dashed border-[#fff1e3]/20 pt-4">
                <div className="flex items-center gap-3">
                  <div className="h-12 w-12 shrink-0 overflow-hidden rounded-xl bg-[#f5e6d0]">
                    <Image
                      src={REWARD.image}
                      alt="Sandwich reward"
                      width={48}
                      height={48}
                      className="h-full w-full object-cover"
                    />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className={`text-xs font-semibold ${rewardReady ? "text-[#fdc647]" : "text-[#fff1e3]/75"}`}>
                      {rewardReady ? "Ready to claim" : "Your reward"}
                    </p>
                    <h2 className="font-display mt-0.5 truncate text-lg font-bold leading-tight text-[#fff1e3]">
                      {REWARD.title}
                    </h2>
                    <p className="mt-0.5 text-sm text-[#fff1e3]/85">{REWARD.subtitle}</p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    if (!rewardReady || !redeemToken) return;
                    setOpenedRedeemToken(redeemToken ?? openedRedeemToken);
                    setShowRedeem(true);
                  }}
                  disabled={!rewardReady}
                  aria-disabled={!rewardReady}
                  className={`mt-4 flex h-14 w-full items-center justify-center gap-2 rounded-2xl text-sm font-bold transition-transform focus-visible:outline-offset-4 ${
                    rewardReady
                      ? "animate-pulse-glow bg-[#fdc647] text-yellow-900 active:scale-[0.99]"
                      : "cursor-not-allowed bg-[#fff1e3]/10 text-[#fff1e3]/50"
                  }`}
                >
                  <Gift className="h-5 w-5" />
                  Claim Reward
                </button>
              </div>
            </div>
          </section>

          <section className="loyalty-enter loyalty-enter-3 rounded-3xl border border-[#f0d9b5] bg-white p-5 shadow-sm">
            <div className="mb-4">
              <h2 className="font-display text-xl font-bold text-yellow-900">
                Your stamp code
              </h2>
              <p className="mt-1 text-sm text-yellow-900/90">
                Show this to our staff after your order
              </p>
            </div>

            <QRCodeDisplay stampToken={stampToken} />

            <p className="mt-4 rounded-2xl bg-[#f5e6d0] p-4 text-sm leading-relaxed text-yellow-900/90">
              After each purchase, show this code. Your stamp appears here within seconds.
            </p>
          </section>
        </div>
      </main>

      {showRedeem && (
        <RedeemModal
          reward={REWARD}
          redeemToken={redeemToken ?? openedRedeemToken}
          onClose={() => setShowRedeem(false)}
        />
      )}

      {showRedeemed && (
        <RedeemedScreen reward={REWARD} onClose={handleReset} />
      )}
    </>
  );
}
