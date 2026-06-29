"use client";

import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  ChevronLeft,
  ChevronRight,
  Pencil,
  Check,
  X,
  ShoppingBag,
  Gift,
  MapPin,
  Bell,
  Leaf,
  Star,
  MessageCircle,
  Phone,
  HelpCircle,
  Trash2,
  LogOut,
  LogIn,
  ShieldCheck,
  BadgeCheck,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

// ─── Avatar data — 12 cartoon illustrations via DiceBear SVG API ─────────────
// 6 male seeds, 6 female seeds — fun illustrated style, no photo uploads needed
const AVATARS = [
  { id: "m1", seed: "Felix", label: "Felix", gender: "male" },
  { id: "m2", seed: "Leo", label: "Leo", gender: "male" },
  { id: "m3", seed: "Arjun", label: "Arjun", gender: "male" },
  { id: "m4", seed: "Rohan", label: "Rohan", gender: "male" },
  { id: "m5", seed: "Dev", label: "Dev", gender: "male" },
  { id: "m6", seed: "Kiran", label: "Kiran", gender: "male" },
  { id: "f1", seed: "Priya", label: "Priya", gender: "female" },
  { id: "f2", seed: "Ananya", label: "Ananya", gender: "female" },
  { id: "f3", seed: "Meera", label: "Meera", gender: "female" },
  { id: "f4", seed: "Zara", label: "Zara", gender: "female" },
  { id: "f5", seed: "Divya", label: "Divya", gender: "female" },
  { id: "f6", seed: "Nisha", label: "Nisha", gender: "female" },
];

const avatarUrl = (seed: string) =>
  `https://api.dicebear.com/9.x/adventurer/svg?seed=${seed}&backgroundColor=ffdfbf,ffd5dc,c0aede,b6e3f4,d1d4f9&radius=50`;

// ─── Mock user state ──────────────────────────────────────────────────────────
const MOCK_USER = {
  name: "Ravi Kumar",
  phone: "+91 98765 43210",
  email: "ravi@example.com",
  memberSince: "March 2024",
  stamps: 3,
  totalOrders: 24,
};

// ─── Section row component ────────────────────────────────────────────────────
function Row({
  icon: Icon,
  label,
  sub,
  right,
  danger,
  onClick,
}: {
  icon: React.ElementType;
  label: string;
  sub?: string;
  right?: React.ReactNode;
  danger?: boolean;
  onClick?: () => void;
}) {
  // Using <div> instead of <button> prevents nested-button hydration errors
  // when `right` contains a Toggle (which is itself a <button>).
  // Accessibility is restored via role/tabIndex/onKeyDown.
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
      className={`w-full flex items-center gap-3.5 px-4 py-3.5 transition-colors text-left
        ${onClick ? "cursor-pointer active:bg-[#fff1e3]" : ""}`}
    >
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

// ─── Avatar picker bottom sheet ───────────────────────────────────────────────
function AvatarPicker({
  current,
  onSelect,
  onClose,
}: {
  current: string;
  onSelect: (seed: string) => void;
  onClose: () => void;
}) {
  const sheetRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    gsap.from(sheetRef.current, {
      y: "100%",
      duration: 0.4,
      ease: "power3.out",
    });
  });

  const males = AVATARS.filter((a) => a.gender === "male");
  const females = AVATARS.filter((a) => a.gender === "female");

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-[2px]"
        onClick={onClose}
      />
      <div
        ref={sheetRef}
        className="relative w-full max-w-md bg-white rounded-t-3xl overflow-hidden shadow-2xl"
      >
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-10 h-1 bg-gray-200 rounded-full" />
        </div>

        <div className="px-5 pb-2 flex items-center justify-between">
          <p className="font-black text-base text-[#3d1a00]">
            Pick your avatar
          </p>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[#f5e6d0] flex items-center justify-center"
          >
            <X className="w-4 h-4 text-[#3d1a00]" />
          </button>
        </div>

        <div className="px-5 pb-8 pt-2 space-y-5">
          {/* Male row */}
          <div>
            <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24] mb-3">
              Boys
            </p>
            <div className="grid grid-cols-6 gap-2">
              {males.map((av) => (
                <button
                  key={av.id}
                  onClick={() => {
                    onSelect(av.seed);
                    onClose();
                  }}
                  className={`relative rounded-2xl overflow-hidden border-2 transition-all duration-200 active:scale-90
                    ${
                      current === av.seed
                        ? "border-yellow-900 shadow-lg shadow-yellow-900/20 scale-105"
                        : "border-transparent"
                    }`}
                >
                  <img
                    src={avatarUrl(av.seed)}
                    alt={av.label}
                    className="w-full aspect-square"
                  />
                  {current === av.seed && (
                    <div className="absolute bottom-0.5 right-0.5 w-4 h-4 bg-yellow-900 rounded-full flex items-center justify-center">
                      <Check
                        className="w-2.5 h-2.5 text-white"
                        strokeWidth={3}
                      />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Female row */}
          <div>
            <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24] mb-3">
              Girls
            </p>
            <div className="grid grid-cols-6 gap-2">
              {females.map((av) => (
                <button
                  key={av.id}
                  onClick={() => {
                    onSelect(av.seed);
                    onClose();
                  }}
                  className={`relative rounded-2xl overflow-hidden border-2 transition-all duration-200 active:scale-90
                    ${
                      current === av.seed
                        ? "border-yellow-900 shadow-lg shadow-yellow-900/20 scale-105"
                        : "border-transparent"
                    }`}
                >
                  <img
                    src={avatarUrl(av.seed)}
                    alt={av.label}
                    className="w-full aspect-square"
                  />
                  {current === av.seed && (
                    <div className="absolute bottom-0.5 right-0.5 w-4 h-4 bg-yellow-900 rounded-full flex items-center justify-center">
                      <Check
                        className="w-2.5 h-2.5 text-white"
                        strokeWidth={3}
                      />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Delete account confirmation sheet ───────────────────────────────────────
function DeleteSheet({
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
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"
        onClick={onClose}
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
        <button
          onClick={onConfirm}
          className="w-full h-13 py-3.5 bg-red-500 text-white font-black text-sm rounded-xl mb-3 active:scale-95 transition-transform"
        >
          Yes, delete my account
        </button>
        <button
          onClick={onClose}
          className="w-full h-13 py-3.5 bg-[#f5e6d0] text-[#3d1a00] font-black text-sm rounded-xl active:scale-95 transition-transform"
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

  // Auth state (UI toggle only)
  const [isSignedIn, setIsSignedIn] = useState(true);

  // Profile state
  const [avatarSeed, setAvatarSeed] = useState("Arjun");
  const [name, setName] = useState(MOCK_USER.name);
  const [editingName, setEditingName] = useState(false);
  const [draftName, setDraftName] = useState(name);

  // Sheet visibility
  const [showAvatarPicker, setShowAvatarPicker] = useState(false);
  const [showDeleteSheet, setShowDeleteSheet] = useState(false);
  const [showSignOutSheet, setShowSignOutSheet] = useState(false);

  // Preference toggles
  const [vegOnly, setVegOnly] = useState(false);
  const [orderUpdates, setOrderUpdates] = useState(true);
  const [offers, setOffers] = useState(true);
  const [newItems, setNewItems] = useState(false);

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

  // Save name
  const saveName = () => {
    if (draftName.trim()) setName(draftName.trim());
    setEditingName(false);
  };

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
          onClick={() => setIsSignedIn(true)}
          className="w-full max-w-xs h-14 bg-[#3d1a00] text-white font-black text-sm rounded-2xl flex items-center justify-center gap-3 shadow-lg active:scale-95 transition-transform"
        >
          <LogIn className="w-5 h-5" />
          Continue with Google
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
            <button
              onClick={() => setShowAvatarPicker(true)}
              className="relative mb-4 active:scale-95 transition-transform"
            >
              <div className="w-24 h-24 rounded-3xl overflow-hidden border-4 border-[#c17f24] shadow-xl">
                <img
                  src={avatarUrl(avatarSeed)}
                  alt="avatar"
                  className="w-full h-full"
                />
              </div>
              {/* Edit badge */}
              <div className="absolute -bottom-1.5 -right-1.5 w-7 h-7 bg-[#c17f24] rounded-xl flex items-center justify-center shadow-md border-2 border-[#3d1a00]">
                <Pencil className="w-3 h-3 text-white" strokeWidth={2.5} />
              </div>
            </button>

            {/* Editable name */}
            {editingName ? (
              <div className="flex items-center gap-2 mb-1">
                <input
                  autoFocus
                  value={draftName}
                  onChange={(e) => setDraftName(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && saveName()}
                  className="bg-white/10 border border-white/30 text-yellow-950 font-black text-xl text-center rounded-xl px-3 py-1 outline-none w-44 placeholder:text-white/30"
                />
                <button
                  onClick={saveName}
                  className="w-8 h-8 bg-[#c17f24] rounded-xl flex items-center justify-center active:scale-90"
                >
                  <Check className="w-4 h-4 text-white" strokeWidth={3} />
                </button>
                <button
                  onClick={() => setEditingName(false)}
                  className="w-8 h-8 bg-white/10 rounded-xl flex items-center justify-center active:scale-90"
                >
                  <X className="w-4 h-4 text-white" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => {
                  setDraftName(name);
                  setEditingName(true);
                }}
                className="flex items-center gap-2 mb-1 group"
              >
                <h2 className="font-black text-2xl text-yellow-950 leading-tight">
                  {name}
                </h2>
                <Pencil
                  className="w-3.5 h-3.5 text-white/40 group-active:text-white transition-colors"
                  strokeWidth={2}
                />
              </button>
            )}

            {/* Verified phone */}
            <div className="flex items-center gap-1.5 mb-3">
              <p className="text-[#c9a87c] text-sm">{MOCK_USER.phone}</p>
              <BadgeCheck className="w-4 h-4 text-[#c17f24]" strokeWidth={2} />
            </div>

            {/* Stats strip */}
            <div className="flex items-center gap-5 mt-1">
              <div className="text-center">
                <p className="text-yellow-700 font-black text-lg leading-none">
                  {MOCK_USER.totalOrders}
                </p>
                <p className="text-[#c9a87c] text-[10px] font-semibold mt-0.5">
                  Orders
                </p>
              </div>
              <div className="w-px h-8 bg-white/15" />
              <div className="text-center">
                <p className="text-yellow-700 font-black text-lg leading-none">
                  {MOCK_USER.stamps}/6
                </p>
                <p className="text-[#c9a87c] text-[10px] font-semibold mt-0.5">
                  Stamps
                </p>
              </div>
              <div className="w-px h-8 bg-white/15" />
              <div className="text-center">
                <p className="text-[#c17f24] font-black text-lg leading-none">
                  Gold
                </p>
                <p className="text-[#c9a87c] text-[10px] font-semibold mt-0.5">
                  Member
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Member since tag */}
        <div className="profile-section flex justify-center -mt-4 mb-5 relative z-10">
          <div className="bg-[#c17f24] text-[#3d1a00] text-[10px] font-black tracking-widest uppercase px-4 py-1.5 rounded-full shadow-md">
            Member since {MOCK_USER.memberSince}
          </div>
        </div>

        <div className="space-y-3">
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
              sub="1 order currently active"
            />
            <Divider />
            <Row
              icon={Gift}
              label="Loyalty Rewards"
              sub={`${MOCK_USER.stamps} of 6 stamps collected`}
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
              onClick={() => setVegOnly(!vegOnly)}
              right={
                <Toggle on={vegOnly} onToggle={() => setVegOnly(!vegOnly)} />
              }
            />
          </SectionCard>

          {/* ── 4. NOTIFICATIONS ──────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Notifications
              </p>
            </div>
            <Row
              icon={Bell}
              label="Order updates"
              sub="Status changes for your orders"
              onClick={() => setOrderUpdates(!orderUpdates)}
              right={
                <Toggle
                  on={orderUpdates}
                  onToggle={() => setOrderUpdates(!orderUpdates)}
                />
              }
            />
            <Divider />
            <Row
              icon={Star}
              label="Offers & promos"
              sub="Deals and discount codes"
              onClick={() => setOffers(!offers)}
              right={<Toggle on={offers} onToggle={() => setOffers(!offers)} />}
            />
            <Divider />
            <Row
              icon={Bell}
              label="New menu items"
              sub="When we add something fresh"
              onClick={() => setNewItems(!newItems)}
              right={
                <Toggle on={newItems} onToggle={() => setNewItems(!newItems)} />
              }
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
              icon={HelpCircle}
              label="FAQs"
              sub="Quick answers to common questions"
            />
            <Divider />
            <Row
              icon={MessageCircle}
              label="Chat on WhatsApp"
              sub="+91 98765 43210"
              onClick={() =>
                window.open("https://wa.me/919876543210", "_blank")
              }
            />
            <Divider />
            <Row
              icon={Phone}
              label="Call us"
              sub="Mon–Sun, 9 AM – 10 PM"
              onClick={() => window.open("tel:+919876543210")}
            />
            <Divider />
            <Row
              icon={Star}
              label="Rate the app"
              sub="Enjoying Slice and Serve?"
            />
          </SectionCard>

          {/* ── 6. ACCOUNT ────────────────────────────────────────── */}
          <SectionCard>
            <div className="px-4 pt-3 pb-1">
              <p className="text-[10px] font-black tracking-widest uppercase text-[#c17f24]">
                Account
              </p>
            </div>
            <Row
              icon={ShieldCheck}
              label="Signed in with Google"
              sub={MOCK_USER.email}
              right={<BadgeCheck className="w-5 h-5 text-[#c17f24] shrink-0" />}
            />
            <Divider />
            <Row
              icon={MapPin}
              label="Saved addresses"
              sub="Manage delivery locations"
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
              onClick={() => setShowDeleteSheet(true)}
            />
          </SectionCard>

          {/* App version footer */}
          <p className="text-center text-[10px] text-[#3d1a00]/25 font-medium pt-1">
            Slice and Serve · v1.0.0
          </p>
        </div>
      </div>

      {/* ── Sheets ───────────────────────────────────────────────── */}
      {showAvatarPicker && (
        <AvatarPicker
          current={avatarSeed}
          onSelect={setAvatarSeed}
          onClose={() => setShowAvatarPicker(false)}
        />
      )}
      {showDeleteSheet && (
        <DeleteSheet
          onClose={() => setShowDeleteSheet(false)}
          onConfirm={() => {
            setIsSignedIn(false);
            setShowDeleteSheet(false);
          }}
        />
      )}
      {showSignOutSheet && (
        <SignOutSheet
          onClose={() => setShowSignOutSheet(false)}
          onConfirm={() => {
            setIsSignedIn(false);
            setShowSignOutSheet(false);
          }}
        />
      )}
    </>
  );
}
