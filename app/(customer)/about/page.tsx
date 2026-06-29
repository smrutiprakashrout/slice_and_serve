"use client";

import { useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import {
  Leaf,
  Flame,
  ShieldCheck,
  Truck,
  Star,
  MapPin,
  Phone,
  Clock,
  ChevronDown,
  Heart,
  Award,
  Users,
  Utensils,
  CheckCircle2,
  ChevronRight,
} from "lucide-react";
import { FaInstagram, FaFacebook } from "react-icons/fa";

// ─── Data ─────────────────────────────────────────────────────────────────────

const STATS = [
  { value: 10000, suffix: "+", label: "Meals Served" },
  { value: 4, suffix: "+", label: "Years Running" },
  { value: 98, suffix: "%", label: "Happy Customers" },
  { value: 50, suffix: "+", label: "Menu Items" },
];

const VALUES = [
  {
    icon: Leaf,
    title: "Farm Fresh",
    desc: "Vegetables and produce sourced fresh every morning, never frozen.",
  },
  {
    icon: Flame,
    title: "Made to Order",
    desc: "Every dish is cooked fresh when you order — no pre-cooked batches.",
  },
  {
    icon: ShieldCheck,
    title: "Hygiene First",
    desc: "FSSAI certified kitchen with daily deep cleaning and sanitisation.",
  },
  {
    icon: Truck,
    title: "Fast Delivery",
    desc: "Hot food at your doorstep via Zomato & Swiggy, within 30 minutes.",
  },
  {
    icon: Heart,
    title: "No Preservatives",
    desc: "We use no artificial colours, flavours, or preservatives — ever.",
  },
  {
    icon: Users,
    title: "Family Friendly",
    desc: "A place where everyone from kids to grandparents feels at home.",
  },
];

const TEAM = [
  {
    name: "Chef Serferaz Khan",
    role: "Head Chef",
    emoji: "👨‍🍳",
    since: "3 yrs experience",
    desc: "With 3 years of culinary experience, Chef Arjun brings bold flavours and technical precision to every dish. His Chicken 65 Sandwich is legendary.",
  },
];

const HYGIENE = [
  "Deep kitchen cleaning twice daily",
  "Fresh oil used for every service",
  "Filtered and purified water only",
  "Gloves & hairnets worn at all times",
  "Regular pest control & sanitisation",
  "FSSAI certified food safety standards",
  "Contactless packaging available",
  "Staff health checks every week",
];

const INGREDIENTS = [
  {
    emoji: "🥬",
    label: "Farm-fresh vegetables",
    sub: "Sourced locally every morning",
  },
  { emoji: "🍗", label: "Fresh chicken daily", sub: "No frozen poultry, ever" },
  { emoji: "🌶️", label: "Premium spices", sub: "Hand-ground in-house" },
  { emoji: "🍞", label: "Freshly baked bread", sub: "Delivered each morning" },
  { emoji: "🫙", label: "Homemade sauces", sub: "No store-bought shortcuts" },
  { emoji: "🧄", label: "Pure desi ghee", sub: "For authentic flavour" },
];

const REVIEWS = [
  {
    name: "Priya S.",
    rating: 5,
    location: "Salipur",
    text: "The Chicken 65 Sandwich is out of this world! So fresh, so flavourful. My go-to lunch every week.",
  },
  {
    name: "Amit R.",
    rating: 5,
    location: "Cuttack",
    text: "Love that everything is cooked fresh. You can actually taste the difference. FSSAI certified gives extra confidence.",
  },
  {
    name: "Sunita M.",
    rating: 5,
    location: "Salipur",
    text: "Ordered via Swiggy and it arrived hot and perfectly packed. The Paneer Sandwich was absolutely delicious!",
  },
  {
    name: "Dev K.",
    rating: 4,
    location: "Bhubaneswar",
    text: "Great value for money. The portions are generous and the staff is always warm and helpful. Highly recommend!",
  },
];

const FAQS = [
  {
    q: "Do you offer home delivery?",
    a: "Yes! We're available on both Zomato and Swiggy for fast delivery within the local area.",
  },
  {
    q: "Do you have vegetarian options?",
    a: "Absolutely. We have a wide range of veg sandwiches, paneer starters, crispy corn, and more.",
  },
  {
    q: "Do you cater for events and parties?",
    a: "Yes, we offer party packages and bulk orders. Contact us at least 24 hours in advance.",
  },
  {
    q: "Do you accept online payments?",
    a: "Yes — UPI, cards, and all major wallets are accepted both in-store and online.",
  },
  {
    q: "What are your hygiene standards?",
    a: "We are FSSAI certified, clean our kitchen twice daily, and use fresh ingredients with no preservatives.",
  },
  {
    q: "Is parking available?",
    a: "Yes, street parking is available right outside the restaurant at Saheswari Club, Salipur.",
  },
];

const TICKER_ITEMS = [
  "🥪 Fresh Sandwiches",
  "🍗 Chicken 65",
  "🥤 Chilled Drinks",
  "🍔 Juicy Burgers",
  "🧅 Crispy Corn",
  "🌶️ Chilli Chicken",
  "🍞 Fresh Bread Daily",
  "🫙 Homemade Sauces",
  "🥬 Farm Vegetables",
  "❤️ Made With Love",
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={`w-3.5 h-3.5 ${i < rating ? "fill-[#c17f24] text-[#c17f24]" : "fill-gray-200 text-gray-200"}`}
        />
      ))}
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-[10px] font-black tracking-[0.25em] uppercase text-[#c17f24] mb-3">
      {children}
    </p>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function AboutPage() {
  const tickerRef = useRef<HTMLDivElement>(null);
  const faqOpenRef = useRef<number | null>(null);
  const faqRefs = useRef<(HTMLDivElement | null)[]>([]);
  const animsRef = useRef<any[]>([]); // store all anime instances for cleanup

  // ── FAQ accordion — pure CSS height transition, no animation library needed ─
  const toggleFaq = (index: number) => {
    const prev = faqOpenRef.current;
    // close previous
    if (prev !== null && prev !== index) {
      const prevEl = faqRefs.current[prev];
      if (prevEl) {
        prevEl.style.height = prevEl.scrollHeight + "px";
        requestAnimationFrame(() => {
          prevEl.style.height = "0px";
        });
      }
    }
    const el = faqRefs.current[index];
    if (!el) return;
    if (prev === index) {
      el.style.height = el.scrollHeight + "px";
      requestAnimationFrame(() => {
        el.style.height = "0px";
      });
      faqOpenRef.current = null;
    } else {
      el.style.height = "0px";
      requestAnimationFrame(() => {
        el.style.height = el.scrollHeight + "px";
      });
      faqOpenRef.current = index;
    }
  };

  // ── All animations ─────────────────────────────────────────────────────────
  useEffect(() => {
    // Dynamically import animejs v4 to avoid SSR issues
    import("animejs").then(({ animate, createTimeline, onScroll, stagger }) => {
      const anims: any[] = [];

      // ── STRATEGY ───────────────────────────────────────────────────────────
      // 1. All animated elements start VISIBLE in HTML (no hidden classes).
      // 2. We use anime's `from` tween parameter to define the start state.
      //    This means anime sets the start state right when it creates the
      //    animation — just before it plays — not on page load.
      // 3. For scroll animations, `autoplay: onScroll(...)` with `sync: 'play pause'`
      //    plays the animation once when the element enters the viewport.
      // 4. If anime fails to load, all elements remain visible. Safe fallback.

      // ── 1. HERO entrance timeline ────────────────────────────────────────
      const heroImg = document.querySelector<HTMLElement>(".a-hero-img");
      const heroTitle = document.querySelector<HTMLElement>(".a-hero-title");
      const heroSub = document.querySelector<HTMLElement>(".a-hero-sub");
      const heroBadges =
        document.querySelectorAll<HTMLElement>(".a-hero-badge");
      const heroScroll = document.querySelector<HTMLElement>(".a-hero-scroll");

      if (heroImg && heroTitle && heroSub) {
        const tl = createTimeline({ defaults: { ease: "outExpo" } });
        tl.add(heroImg, { opacity: [0, 1], scale: [1.06, 1], duration: 1000 })
          .add(
            heroTitle,
            { opacity: [0, 1], translateY: [40, 0], duration: 800 },
            400,
          )
          .add(
            heroSub,
            { opacity: [0, 1], translateY: [24, 0], duration: 700 },
            900,
          )
          .add(
            heroBadges,
            {
              opacity: [0, 1],
              translateY: [14, 0],
              duration: 500,
              delay: stagger(80),
            },
            1100,
          );
        if (heroScroll)
          tl.add(heroScroll, { opacity: [0, 0.5], duration: 400 }, 1400);
        anims.push(tl);
      }

      // ── 2. TICKER — CSS animation, no JS needed ───────────────────────────
      // Handled entirely in CSS keyframes below — zero JS, perfectly reliable.

      // ── 3. STATS count-up ────────────────────────────────────────────────
      const statsSection =
        document.querySelector<HTMLElement>(".a-stats-section");
      if (statsSection) {
        const statEls =
          statsSection.querySelectorAll<HTMLElement>(".a-stat-num");
        let fired = false;
        const io = new IntersectionObserver(
          (entries) => {
            if (entries[0].isIntersecting && !fired) {
              fired = true;
              io.disconnect();
              statEls.forEach((el, i) => {
                const end = STATS[i]?.value ?? 0;
                const obj = { n: 0 };
                const a = animate(obj, {
                  n: end,
                  duration: 2000,
                  delay: i * 100,
                  ease: "outQuad",
                  onUpdate: () => {
                    el.textContent = Math.round(obj.n).toLocaleString();
                  },
                  onComplete: () => {
                    el.textContent = end.toLocaleString();
                  },
                });
                anims.push(a);
              });
            }
          },
          { threshold: 0.3 },
        );
        io.observe(statsSection);
      }

      // ── 4. SCROLL REVEALS using IntersectionObserver ─────────────────────
      // We use native IntersectionObserver instead of onScroll() because it:
      // - works on any scroll container
      // - fires correctly for elements already in viewport
      // - has zero dependency on window scroll events
      // Each element type gets its own observer + animation.

      function revealOnScroll(
        selector: string,
        fromProps: Record<string, [number, number]>,
        options: {
          duration?: number;
          ease?: string;
          delayFn?: (el: Element, i: number) => number;
        } = {},
      ) {
        const els = Array.from(
          document.querySelectorAll<HTMLElement>(selector),
        );
        if (!els.length) return;

        // Set initial (hidden) state right now
        els.forEach((el) => {
          Object.entries(fromProps).forEach(([prop, [from]]) => {
            if (prop === "opacity") el.style.opacity = String(from);
            else if (prop === "translateY")
              el.style.transform = `translateY(${from}px)`;
            else if (prop === "translateX")
              el.style.transform = `translateX(${from}px)`;
            else if (prop === "scale") el.style.transform = `scale(${from})`;
          });
        });

        const { duration = 700, ease = "outExpo", delayFn } = options;
        const seen = new Set<Element>();

        const io = new IntersectionObserver(
          (entries) => {
            entries.forEach((entry) => {
              if (entry.isIntersecting && !seen.has(entry.target)) {
                seen.add(entry.target);
                const el = entry.target as HTMLElement;
                const idx = els.indexOf(el);
                const toProps: Record<string, number> = {};
                Object.entries(fromProps).forEach(([prop, [, to]]) => {
                  toProps[prop] = to;
                });
                const a = animate(el, {
                  ...toProps,
                  duration,
                  ease,
                  delay: delayFn ? delayFn(el, idx) : 0,
                });
                anims.push(a);
              }
            });
          },
          { threshold: 0.05, rootMargin: "0px 0px -40px 0px" },
        );

        els.forEach((el) => io.observe(el));
      }

      // Headings — fade + slide up
      revealOnScroll(
        ".a-heading",
        { opacity: [0, 1], translateY: [28, 0] },
        { duration: 700, ease: "outExpo" },
      );

      // Generic up reveals
      revealOnScroll(
        ".a-up",
        { opacity: [0, 1], translateY: [32, 0] },
        { duration: 650, ease: "outExpo" },
      );

      // Left reveals
      revealOnScroll(
        ".a-left",
        { opacity: [0, 1], translateX: [-30, 0] },
        { duration: 650, ease: "outExpo" },
      );

      // Scale pop
      revealOnScroll(
        ".a-scale",
        { opacity: [0, 1], scale: [0.88, 1] },
        { duration: 550, ease: "outBack(1.4)" },
      );

      // Cards — stagger via delay function based on index within their parent
      revealOnScroll(
        ".a-card",
        { opacity: [0, 1], translateY: [28, 0] },
        {
          duration: 550,
          ease: "outExpo",
          delayFn: (el) => {
            const parent = el.parentElement;
            if (!parent) return 0;
            const siblings = Array.from(parent.querySelectorAll(".a-card"));
            return siblings.indexOf(el) * 80;
          },
        },
      );

      // Hygiene items — stagger slide from left
      revealOnScroll(
        ".a-hygiene",
        { opacity: [0, 1], translateX: [-24, 0] },
        {
          duration: 500,
          ease: "outExpo",
          delayFn: (_el, i) => i * 55,
        },
      );

      animsRef.current = anims;
    });

    // ── TICKER — CSS only, set up via JS for correct width ─────────────────
    const ticker = tickerRef.current;
    if (ticker) {
      const style = document.createElement("style");
      style.textContent = `
        @keyframes ticker-scroll {
          0%   { transform: translateX(0); }
          100% { transform: translateX(-33.333%); }
        }
        .ticker-inner { animation: ticker-scroll 28s linear infinite; }
      `;
      document.head.appendChild(style);
      return () => {
        document.head.removeChild(style);
      };
    }
  }, []);
  const router = useRouter();
  return (
    <div className="bg-[#fff1e3] font-sans text-[#3d1a00] pb-32">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;900&display=swap');
        .font-display    { font-family: 'Playfair Display', Georgia, serif; }
        .font-body       { font-family: 'Inter', system-ui, sans-serif; }
        .section-divider { height:1px; background:linear-gradient(to right,transparent,#c17f2440,transparent); margin:0 1.5rem; }
        .ticker-wrap     { overflow:hidden; }
        .ticker-inner    { display:flex; gap:2.5rem; white-space:nowrap; width:max-content; }
        .faq-body        { overflow:hidden; height:0; transition:height 0.35s cubic-bezier(0.4,0,0.2,1); }
      `}</style>

      {/* ── HERO ──────────────────────────────────────────────────────── */}
      <section className="relative min-h-[70vh] flex flex-col px-6 pb-10 overflow-hidden">
        <div className="relative z-10 mt-24">
          <div className="a-hero-img rounded-2xl w-full h-[30vh] overflow-hidden">
            <Image
              src="/images/shop.png"
              alt="Slice & Serve"
              width={900}
              height={900}
              className="w-full h-full object-cover"
              priority
            />
          </div>
          <h1 className="a-hero-title font-display text-4xl font-black text-yellow-900 leading-[1.08] mb-4 pt-6">
            Fresh Food.
            <br />
            Warm
            <br />
            Hospitality.
          </h1>
          <p className="a-hero-sub font-body text-yellow-700 text-base leading-relaxed mb-6 max-w-xs">
            Authentic flavours made with fresh ingredients, cooked to order —
            every single day.
          </p>
          <div className="flex gap-2 flex-wrap">
            {["🛡️ FSSAI Certified", "✨ No Preservatives", "🛵 On Zomato"].map(
              (b) => (
                <span
                  key={b}
                  className="a-hero-badge bg-white/10 border border-yellow-900/20 text-yellow-900 text-[11px] font-bold px-3 py-1.5 rounded-full"
                >
                  {b}
                </span>
              ),
            )}
          </div>
        </div>
        <div className="a-hero-scroll absolute bottom-4 right-6 flex flex-col items-center gap-1">
          <p className="text-[9px] tracking-widest uppercase text-[#3d1a00]/50">
            Scroll
          </p>
          <ChevronDown className="w-4 h-4 text-[#3d1a00]/50 animate-bounce" />
        </div>
      </section>

      {/* ── TICKER ────────────────────────────────────────────────────── */}
      <div className="ticker-wrap bg-[#c17f24] py-3">
        <div ref={tickerRef} className="ticker-inner">
          {/* 3 copies so the CSS loop is seamless at -33.333% */}
          {[...TICKER_ITEMS, ...TICKER_ITEMS, ...TICKER_ITEMS].map(
            (item, i) => (
              <span
                key={i}
                className="text-[#3d1a00] font-black text-[13px] shrink-0"
              >
                {item}
                <span className="mx-5 text-[#3d1a00]/40">·</span>
              </span>
            ),
          )}
        </div>
      </div>

      {/* ── STATS ─────────────────────────────────────────────────────── */}
      <section className="a-stats-section bg-[#3d1a00] px-6 py-8">
        <div className="grid grid-cols-2 gap-6">
          {STATS.map((stat, i) => (
            <div key={i} className="text-center">
              <p className="font-display text-4xl font-black text-[#c17f24] leading-none">
                <span className="a-stat-num">0</span>
                <span>{stat.suffix}</span>
              </p>
              <p className="text-[#c9a87c] text-xs font-semibold mt-1 tracking-wide">
                {stat.label}
              </p>
            </div>
          ))}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── VALUES ────────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Mission &amp; Values</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-2">
          What we stand for
        </h2>
        <p className="a-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          These aren&apos;t just words on a wall — they&apos;re the decisions we
          make in the kitchen every single day.
        </p>
        <div className="grid grid-cols-1 gap-4">
          {VALUES.map((v, i) => {
            const Icon = v.icon;
            return (
              <div
                key={i}
                className="a-card flex gap-4 items-start bg-white rounded-2xl p-4 border border-[#f0d9b5] shadow-sm"
              >
                <div className="w-10 h-10 bg-[#fff1e3] rounded-xl flex items-center justify-center shrink-0">
                  <Icon className="w-5 h-5 text-[#c17f24]" strokeWidth={2} />
                </div>
                <div>
                  <p className="font-body font-black text-sm text-[#3d1a00] mb-0.5">
                    {v.title}
                  </p>
                  <p className="font-body text-xs text-[#3d1a00]/60 leading-relaxed">
                    {v.desc}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── TEAM ──────────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Meet the Team</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-8">
          The people behind
          <br />
          every bite
        </h2>
        <div className="space-y-5">
          {TEAM.map((person, i) => (
            <div
              key={i}
              className="a-card bg-[#3d1a00] rounded-2xl p-5 text-[#fff1e3]"
            >
              <div className="flex items-center gap-4 mb-3">
                <div className="w-14 h-14 bg-[#c17f24]/20 border-2 border-[#c17f24]/40 rounded-2xl flex items-center justify-center text-3xl shrink-0">
                  {person.emoji}
                </div>
                <div>
                  <p className="font-body font-black text-base leading-tight">
                    {person.name}
                  </p>
                  <p className="text-[#c17f24] text-[11px] font-bold tracking-wide">
                    {person.role}
                  </p>
                  <p className="text-[#c9a87c] text-[10px] mt-0.5">
                    {person.since}
                  </p>
                </div>
              </div>
              <p className="font-body text-sm text-[#c9a87c] leading-relaxed">
                {person.desc}
              </p>
            </div>
          ))}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── WHY US ────────────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-white">
        <SectionLabel>Why Choose Us</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-8">
          The Slice &amp; Serve
          <br />
          difference
        </h2>
        <div className="grid grid-cols-2 gap-3">
          {[
            { icon: "🌿", label: "Fresh Daily" },
            { icon: "⚡", label: "Fast Service" },
            { icon: "💰", label: "Affordable" },
            { icon: "🛡️", label: "FSSAI Certified" },
            { icon: "👨‍👩‍👧", label: "Family Friendly" },
            { icon: "📱", label: "Online Ordering" },
            { icon: "🚫", label: "No Preservatives" },
            { icon: "🍳", label: "Made to Order" },
          ].map((item, i) => (
            <div
              key={i}
              className="a-card bg-[#fff1e3] rounded-2xl p-4 text-center border border-[#f0d9b5]"
            >
              <p className="text-2xl mb-2">{item.icon}</p>
              <p className="font-body font-black text-xs text-[#3d1a00]">
                {item.label}
              </p>
            </div>
          ))}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── HYGIENE ───────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Hygiene &amp; Quality</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-2">
          Our kitchen is as
          <br />
          clean as your home
        </h2>
        <p className="a-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          Every meal we serve carries our name — so hygiene is non-negotiable,
          not optional.
        </p>
        <div className="space-y-3">
          {HYGIENE.map((item, i) => (
            <div
              key={i}
              className="a-hygiene flex items-center gap-3 bg-white rounded-xl px-4 py-3 border border-[#f0d9b5]"
            >
              <CheckCircle2
                className="w-5 h-5 text-[#c17f24] fill-[#fff1e3] shrink-0"
                strokeWidth={2}
              />
              <p className="font-body text-sm font-medium text-[#3d1a00]">
                {item}
              </p>
            </div>
          ))}
        </div>
        <div className="a-up mt-6 bg-[#3d1a00] rounded-2xl px-5 py-4 flex items-center gap-4">
          <div className="w-12 h-12 bg-[#c17f24]/20 rounded-xl flex items-center justify-center shrink-0">
            <Award className="w-6 h-6 text-[#c17f24]" />
          </div>
          <div>
            <p className="text-[#c17f24] text-[10px] font-black tracking-widest uppercase">
              Certified
            </p>
            <p className="text-[#fff1e3] font-black text-sm">
              FSSAI Food Safety License
            </p>
            <p className="text-[#c9a87c] text-[11px] mt-0.5">
              Issued by Govt. of India · Ministry of Health
            </p>
          </div>
        </div>
      </section>

      <div className="section-divider" />

      {/* ── INGREDIENTS ───────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#3d1a00]/10">
        <SectionLabel>Our Ingredients</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold text-yellow-900 leading-tight mb-2">
          Quality starts at
          <br />
          the source
        </h2>
        <p className="a-up font-body text-sm text-yellow-800 mb-8 leading-relaxed">
          We never take shortcuts with ingredients. Period.
        </p>
        <div className="grid grid-cols-1 gap-3">
          {INGREDIENTS.map((item, i) => (
            <div
              key={i}
              className="a-card flex items-center gap-4 bg-[#3d1a00]/20 border border-[#3d1a00]/10 rounded-xl px-4 py-3"
            >
              <span className="text-2xl shrink-0">{item.emoji}</span>
              <div>
                <p className="text-[#3d1a00] font-black text-sm">
                  {item.label}
                </p>
                <p className="text-[#3d1a00]/60 text-[11px]">{item.sub}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── DELIVERY ──────────────────────────────────────────────────── */}
      <section className="px-6 py-8 bg-white">
        <SectionLabel>Order Online</SectionLabel>
        <h2 className="a-heading font-display text-2xl font-bold mb-6">
          Available on
        </h2>
        <div className="flex gap-4">
          <div className="a-card flex-1 bg-red-50 border border-red-100 rounded-2xl p-5 flex flex-col items-center gap-2">
            <span className="text-3xl">🔴</span>
            <p className="font-black text-base text-red-600">Zomato</p>
            <p className="text-xs text-gray-500 text-center">
              Fast delivery · Track live
            </p>
          </div>
        </div>
      </section>

      <div className="section-divider" />

      {/* ── REVIEWS ───────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Customer Love</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-2">
          Don&apos;t take our
          <br />
          word for it
        </h2>
        <p className="a-up font-body text-sm text-[#3d1a00]/60 mb-8">
          Real words from real customers.
        </p>
        <div className="space-y-4">
          {REVIEWS.map((r, i) => (
            <div
              key={i}
              className="a-card bg-white rounded-2xl p-5 border border-[#f0d9b5] shadow-sm"
            >
              <div className="flex items-center justify-between mb-3">
                <div>
                  <p className="font-black text-sm text-[#3d1a00]">{r.name}</p>
                  <p className="text-[10px] text-[#3d1a00]/40 font-medium">
                    {r.location}
                  </p>
                </div>
                <StarRating rating={r.rating} />
              </div>
              <p className="font-body text-sm text-[#3d1a00]/70 leading-relaxed">
                &quot;{r.text}&quot;
              </p>
            </div>
          ))}
        </div>
        <div className="a-scale mt-6 bg-[#c17f24] rounded-2xl px-5 py-4 flex items-center justify-between">
          <div>
            <p className="text-[#3d1a00] font-black text-2xl">4.9 ⭐</p>
            <p className="text-[#3d1a00]/70 text-xs font-semibold mt-0.5">
              Average rating across platforms
            </p>
          </div>
          <div className="text-right">
            <p className="text-[#3d1a00] font-black text-lg">500+</p>
            <p className="text-[#3d1a00]/70 text-xs font-semibold">Reviews</p>
          </div>
        </div>
      </section>

      <div className="section-divider" />

      {/* ── FAQS ──────────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>FAQ</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold leading-tight mb-8">
          Common questions
        </h2>
        <div className="space-y-3">
          {FAQS.map((faq, i) => (
            <div
              key={i}
              className="a-card bg-white rounded-2xl border border-[#f0d9b5] overflow-hidden"
            >
              <button
                onClick={() => toggleFaq(i)}
                className="w-full flex items-center justify-between px-5 py-4 text-left gap-3"
              >
                <p className="font-black text-sm text-[#3d1a00] leading-snug flex-1">
                  {faq.q}
                </p>
                <ChevronRight className="w-4 h-4 text-[#c17f24] shrink-0" />
              </button>
              <div
                ref={(el) => {
                  faqRefs.current[i] = el;
                }}
                className="faq-body"
              >
                <p className="px-5 pb-4 text-sm text-[#3d1a00]/65 leading-relaxed font-body">
                  {faq.a}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── VISIT US ──────────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#3d1a00]">
        <SectionLabel>Visit Us</SectionLabel>
        <h2 className="a-heading font-display text-3xl font-bold text-[#fff1e3] leading-tight mb-8">
          Come say hello
        </h2>
        <div className="space-y-4">
          {[
            {
              Icon: MapPin,
              title: "Address",
              lines: ["Saheswari Club, Salipur,", "Cuttack, Odisha"],
            },
            {
              Icon: Clock,
              title: "Opening Hours",
              lines: [
                "Mon – Sun: 3:30 PM – 10:00 PM",
                "Open all days including holidays",
              ],
            },
            {
              Icon: Phone,
              title: "Phone",
              lines: ["+91 9337867207", "WhatsApp orders (Party Order only)"],
            },
          ].map(({ Icon, title, lines }, i) => (
            <div
              key={i}
              className="a-left flex items-start gap-4 bg-white/5 border border-white/10 rounded-2xl px-5 py-4"
            >
              <Icon className="w-5 h-5 text-[#c17f24] shrink-0 mt-0.5" />
              <div>
                <p className="text-[#fff1e3] font-black text-sm">{title}</p>
                {lines.map((l, j) => (
                  <p
                    key={j}
                    className={`text-[#c9a87c] mt-0.5 ${j === 0 ? "text-sm" : "text-xs opacity-60"}`}
                  >
                    {l}
                  </p>
                ))}
              </div>
            </div>
          ))}
        </div>
        <div className="a-up mt-5 rounded-2xl overflow-hidden border border-white/10">
          <iframe
            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3737.6533378008357!2d86.10404967606583!3d20.479426706417755!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3a19136cde8116d5%3A0x1cbedbe7a25c752a!2sSLICE%20%26%20SERVE!5e0!3m2!1sen!2sin!4v1782717085208!5m2!1sen!2sin"
            width="100%"
            height="220"
            style={{ border: 0, display: "block" }}
            allowFullScreen
            loading="lazy"
            referrerPolicy="strict-origin-when-cross-origin"
            title="Slice & Serve location"
          />
        </div>
        <div className="mt-5 flex gap-3">
          <button
            className="a-scale flex-1 flex items-center justify-center gap-2 rounded-xl py-3 text-white text-sm font-bold"
            style={{
              background:
                "linear-gradient(135deg, #f58529, #dd2a7b, #8134af, #515bd4)",
            }}
          >
            <FaInstagram size={18} /> Instagram
          </button>
        </div>
      </section>

      {/* ── CTA ───────────────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#c17f24]">
        <div className="a-up text-center">
          <p className="text-[#3d1a00]/60 text-[10px] font-black tracking-[0.25em] uppercase mb-3">
            Ready?
          </p>
          <h2 className="font-display text-3xl font-black text-[#3d1a00] leading-tight mb-2">
            Hungry yet?
          </h2>
          <p className="text-[#3d1a00]/70 text-sm mb-8 leading-relaxed">
            Order online, visit us, or just follow along — we&apos;d love to
            feed you.
          </p>
          <div className="space-y-3">
            <button
              onClick={() => router.push("/")}
              className="w-full h-14 bg-[#3d1a00] text-[#fff1e3] font-black text-sm rounded-2xl flex items-center justify-center gap-2 shadow-xl active:scale-95 transition-transform"
            >
              <Utensils className="w-5 h-5" /> View Our Menu
            </button>
            <button
              onClick={() => (window.location.href = "tel:9337867207")}
              className="w-full h-14 bg-white/30 border-2 border-[#3d1a00]/20 text-[#3d1a00] font-black text-sm rounded-2xl flex items-center justify-center gap-2 active:scale-95 transition-transform"
            >
              <Phone className="w-5 h-5" /> Call to Order
            </button>
          </div>
          <div className="mt-8 flex justify-center gap-6">
            {["10K+\nMeals", "4.9⭐\nRating", "FSSAI\nCertified"].map(
              (item, i) => (
                <div key={i} className="text-center">
                  <p className="font-black text-[#3d1a00] text-sm whitespace-pre-line leading-tight">
                    {item}
                  </p>
                </div>
              ),
            )}
          </div>
        </div>
      </section>
    </div>
  );
}
