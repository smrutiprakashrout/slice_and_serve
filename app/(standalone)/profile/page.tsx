"use client";

import { useState, useRef } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import useSWR from "swr";
import { fetcher } from "@/lib/fetcher";
import { useRouter } from "next/navigation";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  ChevronLeft,
  ChevronRight,
  ShoppingBag,
  Gift,
  Leaf,
  MessageCircle,
  Phone,
  Trash2,
  LogOut,
  LogIn,
  ShieldCheck,
  BadgeCheck,
} from "lucide-react";
import {
  computeOrderStats,
  formatMemberSince,
  formatStampProgress,
} from "@/lib/profile-stats";
import type { ProfileOrder } from "@/lib/profile-stats";

export interface CustomerPreferences {
  vegOnly: boolean;
}

export interface CustomerProfile {
  id: string;
  _id: string;
  name: string;
  email: string;
  photo?: string;
  preferences: CustomerPreferences;
  createdAt?: string;
  updatedAt?: string;
}
interface LoyaltySummary {
  stamps: number;
  totalRequired: number;
}

const CONTACT_PHONE = "+919337867207";
const CONTACT_HOURS = "Mon-Sun, 3:30 PM - 10:00 PM";

gsap.registerPlugin(useGSAP);

const avatarUrl = (seed: string) =>
  `https://api.dicebear.com/9.x/adventurer/svg?seed=${seed}&backgroundColor=ffdfbf,ffd5dc,c0aede,b6e3f4,d1d4f9&radius=50`;

// ─── Section row component ────────────────────────────────────────────────────
function Row({
  icon: Icon,
  label,
  sub,
  right,
  danger,
  onClick,
  href,
}: {
  icon: React.ElementType;
  label: string;
  sub?: string;
  right?: React.ReactNode;
  danger?: boolean;
  onClick?: () => void;
  href?: string;
}) {
  // Using <div> instead of <button> prevents nested-button hydration errors
  // when `right` contains a Toggle (which is itself a <button>).
  // Accessibility is restored via role/tabIndex/onKeyDown.
  const content = (
    <>
      <div
        className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0
        ${danger ? "bg-red-50" : "bg-[#fff1e3]"}`}
      >
        <Icon
          className={`w-4 h-4 ${danger ? "text-red-500" : "text-yellow-900"}`}
          strokeWidth={2}
        />
      </div>
      <div className="flex-1 min-w-0">
        <p
          className={`text-sm font-bold leading-tight ${danger ? "text-red-500" : "text-[#3d1a00]"}`}
        >
          {label}
        </p>
        {sub && <p className="text-[11px] text-[#3d1a00]/40 mt-0.5">{sub}</p>}
      </div>
      {right ??
        (onClick ? (
          <ChevronRight className="w-4 h-4 text-[#3d1a00]/25 shrink-0" />
        ) : null)}
    </>
  );
  const className = `w-full flex items-center gap-3.5 px-4 py-3.5 transition-colors text-left
    ${onClick || href ? "cursor-pointer active:bg-[#fff1e3]" : ""}`;

  if (href) {
    return <a href={href} className={className}>{content}</a>;
  }

  return (
    <div
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
      onClick={onClick}
      onKeyDown={
        onClick
          ? (e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                onClick();
              }
            }
          : undefined
      }
      className={className}
    >
      {content}
    </div>
  );
}

function Divider() {
  return <div className="h-px bg-[#f0d9b5] mx-4" />;
}

function SectionCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-5 bg-white rounded-2xl border border-[#f0d9b5] overflow-hidden shadow-sm">
      {children}
    </div>
  );
}

// ─── Toggle switch ────────────────────────────────────────────────────────────
function Toggle({ on, onToggle }: { on: boolean; onToggle: () => void }) {
  return (
    <button
      onClick={(e) => {
        e.stopPropagation();
        onToggle();
      }}
      className={`w-10 h-6 rounded-full transition-colors duration-300 flex items-center px-0.5
        ${on ? "bg-yellow-900" : "bg-gray-200"}`}
    >
      <div
        className={`w-5 h-5 bg-white rounded-full shadow-sm transition-transform duration-300
        ${on ? "translate-x-4" : "translate-x-0"}`}
      />
    </button>
  );
}

// ─── Delete account confirmation sheet ───────────────────────────────────────
function DeleteSheet({
  onClose,
  onConfirm,
  isDeleting = false,
  error = null,
}: {
  onClose: () => void;
  onConfirm: () => void;
  isDeleting?: boolean;
  error?: string | null;
}) {
  const ref = useRef<HTMLDivElement>(null);
  useGSAP(() => {
    gsap.from(ref.current, { y: "100%", duration: 0.35, ease: "power3.out" });
  });

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"
        onClick={isDeleting ? undefined : onClose}
      />
      <div
        ref={ref}
        className="relative w-full max-w-md bg-white rounded-t-3xl p-6 shadow-2xl"
      >
        <div className="flex justify-center mb-5">
          <div className="w-14 h-14 bg-red-50 rounded-2xl flex items-center justify-center">
            <Trash2 className="w-7 h-7 text-red-500" />
          </div>
        </div>
        <h3 className="font-black text-xl text-[#3d1a00] text-center mb-2">
          Delete Account?
        </h3>
        <p className="text-sm text-[#3d1a00]/50 text-center leading-relaxed mb-6">
          This will permanently delete your account, order history, and loyalty
          stamps. This cannot be undone.
        </p>
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-600 text-center font-medium">
            {error}
          </div>
        )}
        <button
          disabled={isDeleting}
          onClick={onConfirm}
          className={`w-full h-13 py-3.5 bg-red-500 text-white font-black text-sm rounded-xl mb-3 transition-transform ${
            isDeleting
              ? "opacity-60 cursor-not-allowed"
              : "active:scale-95"
          }`}
        >
          {isDeleting ? "Deleting account..." : "Yes, delete my account"}
        </button>
        <button
          disabled={isDeleting}
          onClick={onClose}
          className={`w-full h-13 py-3.5 bg-[#f5e6d0] text-[#3d1a00] font-black text-sm rounded-xl transition-transform ${
            isDeleting
              ? "opacity-60 cursor-not-allowed"
              : "active:scale-95"
          }`}
        >
          Cancel
        </button>
      </div>
    </div>
  );
}

// ─── Sign out confirmation sheet ──────────────────────────────────────────────
function SignOutSheet({
  onClose,
  onConfirm,
}: {
  onClose: () => void;
  onConfirm: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  useGSAP(() => {
    gsap.from(ref.current, { y: "100%", duration: 0.35, ease: "power3.out" });
  });

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div
        ref={ref}
        className="relative w-full max-w-md bg-white rounded-t-3xl p-6 shadow-2xl"
      >
        <div className="flex justify-center mb-5">
          <div className="w-14 h-14 bg-[#fff1e3] rounded-2xl flex items-center justify-center">
            <LogOut className="w-7 h-7 text-yellow-900" />
          </div>
        </div>
        <h3 className="font-black text-xl text-[#3d1a00] text-center mb-2">
          Sign out?
        </h3>
        <p className="text-sm text-[#3d1a00]/50 text-center leading-relaxed mb-6">
          You'll need to sign in with Google again to access your orders and
          loyalty rewards.
        </p>
        <button
          onClick={onConfirm}
          className="w-full py-3.5 bg-yellow-900 text-white font-black text-sm rounded-xl mb-3 active:scale-95 transition-transform"
        >
          Sign out
        </button>
        <button
          onClick={onClose}
          className="w-full py-3.5 bg-[#f5e6d0] text-[#3d1a00] font-black text-sm rounded-xl active:scale-95 transition-transform"
        >
          Stay signed in
        </button>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function ProfilePage() {
  const containerRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  // ── Real session from Auth.js ─────────────────────────────────────────────
  const { data: session, status } = useSession();
  const isSignedIn = status === "authenticated";

  // ── Real customer profile from /api/me via SWR ─────────────────────────────
  const {
    data: customer,
    error: customerError,
    mutate,
  } = useSWR<CustomerProfile>(isSignedIn ? "/api/me" : null, fetcher);

  const {
    data: orders,
    error: ordersError,
    isLoading: ordersLoading,
  } = useSWR<ProfileOrder[]>(isSignedIn ? "/api/orders/me" : null, fetcher);
  const {
    data: loyalty,
    error: loyaltyError,
    isLoading: loyaltyLoading,
  } = useSWR<LoyaltySummary>(isSignedIn ? "/api/loyalty/me" : null, fetcher);

  const sessionInvalid = [customerError, ordersError, loyaltyError]
    .some((error) => (error as (Error & { status?: number }) | undefined)?.status === 401);

  const name = session?.user?.name ?? customer?.name ?? "";

  // Sheet visibility
  const [showDeleteSheet, setShowDeleteSheet] = useState(false);
  const [showSignOutSheet, setShowSignOutSheet] = useState(false);
  const [isDeletingAccount, setIsDeletingAccount] = useState(false);
  const [deleteAccountError, setDeleteAccountError] = useState<string | null>(
    null,
  );

  // Delete account flow
  const handleDeleteAccount = async () => {
    setIsDeletingAccount(true);
    setDeleteAccountError(null);

    try {
      const res = await fetch("/api/me", {
        method: "DELETE",
      });

      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        const message =
          errorData?.error?.message ||
          "Failed to delete account. Please try again.";
        throw new Error(message);
      }

      setShowDeleteSheet(false);
      await signOut({ callbackUrl: "/" });
    } catch (err) {
      console.error("Account deletion error:", err);
      setDeleteAccountError(
        err instanceof Error
          ? err.message
          : "Failed to delete account. Please try again.",
      );
    } finally {
      setIsDeletingAccount(false);
    }
  };

  // Preference values from /api/me (with schema defaults)
  const preferences: CustomerPreferences = customer?.preferences ?? {
    vegOnly: false,
  };

  const vegOnly = preferences.vegOnly;

  const handleTogglePreference = async (key: keyof CustomerPreferences) => {
    const currentVal = preferences[key];
    const nextVal = !currentVal;

    const baseCustomer: CustomerProfile = customer ?? {
      id: session?.user?.id ?? "",
      _id: session?.user?.id ?? "",
      name: session?.user?.name ?? "",
      email: session?.user?.email ?? "",
      preferences: {
        vegOnly: false,
      },
    };

    const updatedCustomer: CustomerProfile = {
      ...baseCustomer,
      preferences: {
        ...baseCustomer.preferences,
        [key]: nextVal,
      },
    };

    try {
      await mutate(
        async () => {
          const res = await fetch("/api/me", {
            method: "PATCH",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              preferences: {
                [key]: nextVal,
              },
            }),
          });
          if (!res.ok) {
            const errData = await res.json().catch(() => ({}));
            throw new Error(
              errData?.error?.message || `Failed to update ${key}`,
            );
          }
          return await res.json();
        },
        {
          optimisticData: updatedCustomer,
          rollbackOnError: true,
          revalidate: false,
        },
      );
    } catch (err) {
      console.error("Failed to update preference:", err);
    }
  };

  const { totalOrders, inProgressOrders } = computeOrderStats(orders);
  const loyaltyErrorStatus = (loyaltyError as (Error & { status?: number }) | undefined)
    ?.status;
  const hasNoLoyaltyCard = loyaltyErrorStatus === 404;
  const stamps = loyalty?.stamps ?? (hasNoLoyaltyCard ? 0 : undefined);
  const totalStamps = loyalty?.totalRequired ?? (hasNoLoyaltyCard ? 10 : undefined);
  const showStampLoading = loyaltyLoading || (!loyalty && !hasNoLoyaltyCard && !loyaltyError);
  const stampStat = showStampLoading
    ? "-"
    : stamps !== undefined && totalStamps !== undefined
      ? `${stamps}/${totalStamps}`
      : "-";
  const stampSubtext =
    stamps !== undefined && totalStamps !== undefined
      ? formatStampProgress(stamps, totalStamps)
      : "-";
  const memberSince = formatMemberSince(customer?.createdAt);

  // Use the customer's Google photo when present; otherwise show their initial.
  const googlePhoto = session?.user?.image ?? customer?.photo ?? null;

  // Entrance animation
  useGSAP(
    () => {
      gsap.from(".profile-section", {
        y: 24,
        opacity: 0,
        duration: 0.5,
        stagger: 0.08,
        ease: "power2.out",
      });
    },
    { scope: containerRef },
  );

  // ── Loading state — avoids flashing signed-out UI during session check ──
  if (status === "loading") {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex items-center justify-center">
        <div className="w-10 h-10 border-4 border-[#c17f24] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // ── Signed-out state ──────────────────────────────────────────────────────
  if (!isSignedIn) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex flex-col items-center justify-center px-8 text-center pb-28">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-5 shadow-sm border border-[#f0d9b5]">
          <img
            src={avatarUrl("Guest")}
            alt="guest"
            className="w-20 h-20 rounded-2xl"
          />
        </div>
        <h2 className="font-black text-2xl text-[#3d1a00] mb-2">
          You're not signed in
        </h2>
        <p className="text-sm text-[#3d1a00]/50 leading-relaxed mb-8">
          Sign in with Google to access your orders, loyalty rewards, and
          profile.
        </p>
        <button
          onClick={() => signIn("google", { callbackUrl: "/profile" })}
          className="w-full max-w-xs h-14 bg-[#3d1a00] text-white font-black text-sm rounded-2xl flex items-center justify-center gap-3 shadow-lg active:scale-95 transition-transform"
        >
          <LogIn className="w-5 h-5" />
          Continue with Google
        </button>
      </div>
    );
  }

  if (sessionInvalid) {
    return (
      <div className="min-h-dvh bg-[#fff1e3] flex flex-col items-center justify-center px-8 text-center pb-28">
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center mb-5 shadow-sm border border-[#f0d9b5]">
          <LogIn className="w-10 h-10 text-yellow-900" aria-hidden="true" />
        </div>
        <h2 className="font-black text-2xl text-[#3d1a00] mb-2">Session expired</h2>
        <p className="text-sm text-[#3d1a00]/70 leading-relaxed mb-8">
          Your session is no longer valid. Please sign in again.
        </p>
        <button
          onClick={() => signIn("google", { callbackUrl: "/profile" })}
          className="w-full max-w-xs h-14 bg-[#3d1a00] text-white font-black text-sm rounded-2xl flex items-center justify-center gap-3 shadow-lg active:scale-95 transition-transform"
        >
          <LogIn className="w-5 h-5" />
          Sign In
        </button>
      </div>
    );
  }

  // ── Signed-in state ───────────────────────────────────────────────────────
  return (
    <>
      <div
        ref={containerRef}
        className="bg-[#fff1e3] min-h-dvh font-sans pb-32"
      >
        {/* ── 1. PROFILE HEADER ─────────────────────────────────── */}
        <div className="profile-section px-6 pt-6 pb-10 relative overflow-hidden">
          {/* Subtle texture */}
          <div
            className="absolute inset-0 opacity-[0.04]"
            style={{
              backgroundImage:
                "radial-gradient(circle at 1px 1px, #fff1e3 1px, transparent 0)",
              backgroundSize: "20px 20px",
            }}
          />

          {/* Back button */}
          <div className="relative z-10 mb-4">
            <button
              onClick={() => router.push("/")}
              className="flex items-center gap-1.5 text-yellow-950/70 active:text-white transition-colors active:scale-95 transform"
            >
              <div className="w-8 h-8 rounded-xl bg-yellow-950/10 flex items-center justify-center">
                <ChevronLeft
                  className="w-5 h-5 text-yellow-950"
                  strokeWidth={2.5}
                />
              </div>
              <span className="text-sm font-bold">Back</span>
            </button>
          </div>

          {/* Avatar */}
          <div className="flex flex-col items-center relative z-10">
            <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-[#c17f24] shadow-xl mb-4 bg-[#3d1a00] flex items-center justify-center">
              {googlePhoto ? (
                <img
                  src={googlePhoto}
                  alt="Profile"
                  className="w-full h-full object-cover"
                />
              ) : (
                <span className="text-white text-3xl font-black">
                  {name.trim().charAt(0).toUpperCase() || "?"}
                </span>
              )}
            </div>
            <h2 className="font-black text-2xl text-yellow-950 leading-tight mb-1">
              {name}
            </h2>

            {/* Stats strip */}
            <div className="flex items-center gap-5 mt-1">
              <div className="text-center">
                <p className="text-yellow-700 font-black text-lg leading-none">
                  {ordersLoading ? "-" : totalOrders}
                </p>
                <p className="text-[#c9a87c] text-[10px] font-semibold mt-0.5">
                  Orders
                </p>
              </div>
              <div className="w-px h-8 bg-white/15" />
              <div className="text-center">
                <p className="text-yellow-700 font-black text-lg leading-none">
                  {stampStat}
                </p>
                <p className="text-[#c9a87c] text-[10px] font-semibold mt-0.5">
                  Stamps
                </p>
              </div>
            </div>
          </div>
        </div>

        {memberSince && (
          <div className="profile-section flex justify-center -mt-4 mb-5 relative z-10">
            <div className="bg-[#c17f24] text-[#3d1a00] text-[10px] font-black tracking-widest uppercase px-4 py-1.5 rounded-full shadow-md">
              Member since {memberSince}
            </div>
          </div>
        )}

        <div className="space-y-3">
          {customerError && (
            <div className="mx-5 mb-3 p-3.5 bg-amber-500/10 border border-amber-500/20 rounded-2xl flex items-center justify-between text-xs text-amber-900">
              <span>Failed to load profile details.</span>
              <button
                type="button"
                onClick={() => mutate()}
                className="font-bold underline text-[#c17f24] hover:text-[#3d1a00] transition-colors ml-2"
              >
                Retry
              </button>
            </div>
          )}

          {/* ── 2. ACTIVITY ───────────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Activity
              </p>
            </div>
            <Row
              icon={ShoppingBag}
              label="My Orders"
              sub={
                ordersLoading
                  ? "-"
                  : inProgressOrders === 0
                    ? "No active orders"
                    : `${inProgressOrders} ${inProgressOrders === 1 ? "order" : "orders"} in progress`
              }
              onClick={() => router.push("/orders")}
            />
            <Divider />
            <Row
              icon={Gift}
              label="Loyalty Rewards"
              sub={stampSubtext}
              onClick={() => router.push("/loyalty")}
            />
          </SectionCard>

          {/* ── 3. PREFERENCES ────────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Preferences
              </p>
            </div>
            <Row
              icon={Leaf}
              label="Veg only mode"
              sub="Hide non-veg items from menu"
              onClick={() => handleTogglePreference("vegOnly")}
              right={
                <Toggle
                  on={vegOnly}
                  onToggle={() => handleTogglePreference("vegOnly")}
                />
              }
            />
          </SectionCard>

          {/* ── 4. ACCOUNT ────────────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Account
              </p>
            </div>
            <Row
              icon={ShieldCheck}
              label="Signed in with Google"
              sub={session?.user?.email ?? customer?.email ?? ""}
              right={<BadgeCheck className="w-5 h-5 text-[#c17f24] shrink-0" />}
            />
          </SectionCard>

          {/* ── 5. HELP & SUPPORT ─────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Help & Support
              </p>
            </div>
            <Row
              icon={MessageCircle}
              label="Chat on WhatsApp"
              sub="+91 93378 67207 (party orders)"
              href={`https://wa.me/${CONTACT_PHONE.slice(1)}`}
            />
            <Divider />
            <Row
              icon={Phone}
              label="Call us"
              sub={CONTACT_HOURS}
              href={`tel:${CONTACT_PHONE}`}
            />
          </SectionCard>

          {/* ── 7. DANGER ZONE ────────────────────────────────────── */}
          <SectionCard>
            <Row
              icon={LogOut}
              label="Sign out"
              danger
              onClick={() => setShowSignOutSheet(true)}
            />
            <Divider />
            <Row
              icon={Trash2}
              label="Delete account"
              sub="Permanently remove all your data"
              danger
              onClick={() => {
                setDeleteAccountError(null);
                setShowDeleteSheet(true);
              }}
            />
          </SectionCard>

        </div>
      </div>

      {/* ── Sheets ───────────────────────────────────────────────── */}
      {showDeleteSheet && (
        <DeleteSheet
          onClose={() => {
            if (!isDeletingAccount) {
              setDeleteAccountError(null);
              setShowDeleteSheet(false);
            }
          }}
          onConfirm={handleDeleteAccount}
          isDeleting={isDeletingAccount}
          error={deleteAccountError}
        />
      )}
      {showSignOutSheet && (
        <SignOutSheet
          onClose={() => setShowSignOutSheet(false)}
          onConfirm={() => {
            setShowSignOutSheet(false);
            signOut({ callbackUrl: "/" });
          }}
        />
      )}
    </>
  );
}
