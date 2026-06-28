"use client";

import { useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import { ScrollTrigger } from "gsap/ScrollTrigger";
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
  Share2,
  ThumbsUp,
  ChevronRight,
} from "lucide-react";

gsap.registerPlugin(ScrollTrigger, useGSAP);

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
    desc: "With 3 years of culinary experience, Chef Arjun brings bold flavours and technical precision to every dish. His Chicken 65 Sandwich is legendary.",
    emoji: "👨‍🍳",
    since: "3 yrs experience",
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
    text: "The Chicken 65 Sandwich is out of this world! So fresh, so flavourful. My go-to lunch every week.",
    location: "Salipur",
  },
  {
    name: "Amit R.",
    rating: 5,
    text: "Love that everything is cooked fresh. You can actually taste the difference. FSSAI certified gives extra confidence.",
    location: "Cuttack",
  },
  {
    name: "Sunita M.",
    rating: 5,
    text: "Ordered via Swiggy and it arrived hot and perfectly packed. The Paneer Sandwich was absolutely delicious!",
    location: "Salipur",
  },
  {
    name: "Dev K.",
    rating: 4,
    text: "Great value for money. The portions are generous and the staff is always warm and helpful. Highly recommend!",
    location: "Bhubaneswar",
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

// ─── Sub-components ───────────────────────────────────────────────────────────

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

// ─── Main Page ─────────────────────────────────────────────────────────────────
export default function AboutPage() {
  const containerRef = useRef<HTMLDivElement>(null);
  const heroRef = useRef<HTMLDivElement>(null);
  const tickerRef = useRef<HTMLDivElement>(null);
  const statsRef = useRef<HTMLDivElement>(null);
  const faqOpenRef = useRef<number | null>(null);

  // ── GSAP Animations ──
  useGSAP(
    () => {
      // Hero entrance
      const heroTl = gsap.timeline();
      heroTl
        .from(".hero-label", {
          y: 20,
          opacity: 0,
          duration: 0.6,
          ease: "power3.out",
        })
        .from(
          ".hero-title",
          { y: 40, opacity: 0, duration: 0.8, ease: "power3.out" },
          "-=0.3",
        )
        .from(
          ".hero-tagline",
          { y: 24, opacity: 0, duration: 0.6, ease: "power2.out" },
          "-=0.4",
        )
        .from(
          ".hero-badges",
          { y: 16, opacity: 0, duration: 0.5, ease: "power2.out" },
          "-=0.3",
        )
        .from(".hero-scroll", { opacity: 0, duration: 0.4 }, "-=0.1");

      // Ticker infinite scroll
      const tickerEl = tickerRef.current;
      if (tickerEl) {
        const totalWidth = tickerEl.scrollWidth / 2;
        gsap.to(tickerEl, {
          x: -totalWidth,
          duration: 28,
          ease: "none",
          repeat: -1,
        });
      }

      // Stat counters
      const statEls = document.querySelectorAll(".stat-number");
      ScrollTrigger.create({
        trigger: statsRef.current,
        start: "top 80%",
        once: true,
        onEnter: () => {
          statEls.forEach((el, i) => {
            const target = STATS[i].value;
            gsap.from(
              { val: 0 },
              {
                val: target,
                duration: 1.8,
                ease: "power2.out",
                delay: i * 0.12,
                onUpdate: function () {
                  el.textContent = Math.round(
                    this.targets()[0].val,
                  ).toLocaleString();
                },
              },
            );
          });
        },
      });

      // Scroll-triggered section reveals
      gsap.utils.toArray<Element>(".reveal-up").forEach((el, i) => {
        gsap.from(el, {
          scrollTrigger: { trigger: el, start: "top 88%", once: true },
          y: 36,
          opacity: 0,
          duration: 0.65,
          ease: "power3.out",
          delay: (i % 3) * 0.08,
        });
      });

      gsap.utils.toArray<Element>(".reveal-left").forEach((el) => {
        gsap.from(el, {
          scrollTrigger: { trigger: el, start: "top 88%", once: true },
          x: -28,
          opacity: 0,
          duration: 0.6,
          ease: "power2.out",
        });
      });

      // Stagger card grids
      gsap.utils.toArray<Element>(".stagger-parent").forEach((parent) => {
        const children = parent.querySelectorAll(".stagger-child");
        gsap.from(children, {
          scrollTrigger: { trigger: parent, start: "top 85%", once: true },
          y: 30,
          opacity: 0,
          duration: 0.55,
          stagger: 0.1,
          ease: "power2.out",
        });
      });

      // Hygiene checklist items
      gsap.utils.toArray<Element>(".hygiene-item").forEach((el, i) => {
        gsap.from(el, {
          scrollTrigger: { trigger: el, start: "top 90%", once: true },
          x: -20,
          opacity: 0,
          duration: 0.45,
          delay: i * 0.06,
          ease: "power2.out",
        });
      });
    },
    { scope: containerRef },
  );

  // FAQ accordion state outside GSAP
  const faqRefs = useRef<(HTMLDivElement | null)[]>([]);

  const toggleFaq = (index: number) => {
    const current = faqOpenRef.current;
    // Close previously open
    if (current !== null && current !== index && faqRefs.current[current]) {
      gsap.to(faqRefs.current[current], {
        height: 0,
        opacity: 0,
        duration: 0.3,
        ease: "power2.inOut",
      });
    }
    const el = faqRefs.current[index];
    if (!el) return;
    if (current === index) {
      gsap.to(el, {
        height: 0,
        opacity: 0,
        duration: 0.3,
        ease: "power2.inOut",
      });
      faqOpenRef.current = null;
    } else {
      gsap.set(el, { height: "auto" });
      const h = el.offsetHeight;
      gsap.fromTo(
        el,
        { height: 0, opacity: 0 },
        { height: h, opacity: 1, duration: 0.35, ease: "power2.out" },
      );
      faqOpenRef.current = index;
    }
  };

  return (
    <div
      ref={containerRef}
      className="bg-[#fff1e3] font-sans text-[#3d1a00] pb-32"
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;900&display=swap');
        .font-display { font-family: 'Playfair Display', Georgia, serif; }
        .font-body    { font-family: 'Inter', system-ui, sans-serif; }
        .ticker-track { display: flex; gap: 2.5rem; will-change: transform; }
        .section-divider { height: 1px; background: linear-gradient(to right, transparent, #c17f2440, transparent); margin: 0 1.5rem; }
      `}</style>

      {/* ── 1. HERO ──────────────────────────────────────────────────── */}
      <section
        ref={heroRef}
        className="relative min-h-[70vh] flex flex-col justify-end px-6 pt-0 pb-10 overflow-hidden"
      >
        {/* Background texture layer */}
        <div
          className="absolute inset-0 opacity-[0.06]"
          style={{
            backgroundImage:
              "radial-gradient(circle at 1px 1px, #fff1e3 1px, transparent 0)",
            backgroundSize: "24px 24px",
          }}
        />
        {/* Amber glow blob */}
        <div className="absolute top-8 right-0 w-64 h-64 bg-[#c17f24] rounded-full blur-[80px] opacity-20 pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-48 h-48 bg-[#8B1A1A] rounded-full blur-[60px] opacity-25 pointer-events-none" />

        {/* Logo */}

        <div className="relative z-10 mt-26">
          <div className="rounded-2xl w-full h-[30vh] overflow-hidden">
            <Image
              src="/images/shop.png"
              alt=""
              width={900}
              height={900}
              className="w-full h-full object-cover"
            />
          </div>
          <h1 className="hero-title font-display text-4xl font-black text-yellow-900 leading-[1.08] mb-4 pt-6">
            Fresh Food.
            <br />
            Warm
            <br />
            Hospitality.
          </h1>
          <p className="hero-tagline font-body text-yellow-700 text-base leading-relaxed mb-6 max-w-xs">
            Authentic flavours made with fresh ingredients, cooked to order —
            every single day.
          </p>

          {/* Trust badges */}
          <div className="hero-badges flex gap-2 flex-wrap">
            <span className="bg-white/10 border border-yellow-900/20 text-yellow-900 text-[11px] font-bold px-3 py-1.5 rounded-full">
              🛡️ FSSAI Certified
            </span>
            <span className="bg-white/10 border border-yellow-900/20 text-yellow-900 text-[11px] font-bold px-3 py-1.5 rounded-full">
              🛵 On Zomato & Swiggy
            </span>
            <span className="bg-white/10 border border-yellow-900/20 text-yellow-900 text-[11px] font-bold px-3 py-1.5 rounded-full">
              ✨ No Preservatives
            </span>
          </div>
        </div>

        {/* Scroll hint */}
        <div className="hero-scroll absolute bottom-4 right-6 flex flex-col items-center gap-1 opacity-40">
          <p className="text-[9px] tracking-widest uppercase text-[#fff1e3]">
            Scroll
          </p>
          <ChevronDown className="w-4 h-4 text-[#fff1e3] animate-bounce" />
        </div>
      </section>

      {/* ── TICKER TAPE ──────────────────────────────────────────────── */}
      <div className="bg-[#c17f24] py-3 overflow-hidden">
        <div ref={tickerRef} className="ticker-track whitespace-nowrap">
          {[...TICKER_ITEMS, ...TICKER_ITEMS].map((item, i) => (
            <span
              key={i}
              className="text-[#3d1a00] font-black text-[13px] shrink-0"
            >
              {item}
              <span className="mx-5 text-[#3d1a00]/40">·</span>
            </span>
          ))}
        </div>
      </div>

      {/* ── 2. STATS BAR ─────────────────────────────────────────────── */}
      <section ref={statsRef} className="bg-[#3d1a00] px-6 py-8">
        <div className="grid grid-cols-2 gap-6">
          {STATS.map((stat, i) => (
            <div key={i} className="text-center">
              <p className="font-display text-4xl font-black text-[#c17f24] leading-none">
                <span className="stat-number">0</span>
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

      {/* ── 4. MISSION & VALUES ──────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Mission & Values</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-2">
          What we stand for
        </h2>
        <p className="reveal-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          These aren't just words on a wall — they're the decisions we make in
          the kitchen every single day.
        </p>

        <div className="stagger-parent grid grid-cols-1 gap-4">
          {VALUES.map((v, i) => {
            const Icon = v.icon;
            return (
              <div
                key={i}
                className="stagger-child flex gap-4 items-start bg-white rounded-2xl p-4 border border-[#f0d9b5] shadow-sm"
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

      {/* ── 5. MEET THE TEAM ─────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Meet the Team</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-8">
          The people behind
          <br />
          every bite
        </h2>

        <div className="stagger-parent space-y-5">
          {TEAM.map((person, i) => (
            <div
              key={i}
              className="stagger-child bg-[#3d1a00] rounded-2xl p-5 text-[#fff1e3]"
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

      {/* ── 6. WHY CHOOSE US ─────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-white">
        <SectionLabel>Why Choose Us</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-8">
          The Slice & Serve
          <br />
          difference
        </h2>

        <div className="stagger-parent grid grid-cols-2 gap-3">
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
              className="stagger-child bg-[#fff1e3] rounded-2xl p-4 text-center border border-[#f0d9b5]"
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

      {/* ── 7. HYGIENE & QUALITY ─────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Hygiene & Quality</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-2">
          Our kitchen is as
          <br />
          clean as your home
        </h2>
        <p className="reveal-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          Every meal we serve carries our name — so hygiene is non-negotiable,
          not optional.
        </p>

        <div className="space-y-3">
          {HYGIENE.map((item, i) => (
            <div
              key={i}
              className="hygiene-item flex items-center gap-3 bg-white rounded-xl px-4 py-3 border border-[#f0d9b5]"
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

        {/* FSSAI badge */}
        <div className="mt-6 bg-[#3d1a00] rounded-2xl px-5 py-4 flex items-center gap-4 reveal-up">
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

      {/* ── 8. SIGNATURE INGREDIENTS ─────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#3d1a00]/10">
        <SectionLabel>Our Ingredients</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold text-yellow-900 leading-tight mb-2">
          Quality starts at
          <br />
          the source
        </h2>
        <p className="reveal-up font-body text-sm text-yellow-800 mb-8 leading-relaxed">
          We never take shortcuts with ingredients. Period.
        </p>

        <div className="stagger-parent grid grid-cols-1 gap-3">
          {INGREDIENTS.map((item, i) => (
            <div
              key={i}
              className="stagger-child flex items-center gap-4 bg-yellow-900/20 border border-white/10 rounded-xl px-4 py-3"
            >
              <span className="text-2xl shrink-0">{item.emoji}</span>
              <div>
                <p className="text-[#fff1e3] font-black text-sm">
                  {item.label}
                </p>
                <p className="text-yellow-900 text-[11px]">{item.sub}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── 9. DELIVERY PARTNERS ─────────────────────────────────────── */}
      <section className="px-6 py-8 bg-white">
        <SectionLabel>Order Online</SectionLabel>
        <h2 className="reveal-up font-display text-2xl font-bold mb-6">
          Available on
        </h2>
        <div className="stagger-parent flex gap-4">
          {[
            {
              name: "Zomato",
              color: "bg-red-50 border-red-100",
              text: "text-red-600",
              emoji: "🔴",
            },
          ].map((partner, i) => (
            <div
              key={i}
              className={`stagger-child flex-1 ${partner.color} border rounded-2xl p-5 flex flex-col items-center gap-2`}
            >
              <span className="text-3xl">{partner.emoji}</span>
              <p className={`font-black text-base ${partner.text}`}>
                {partner.name}
              </p>
              <p className="text-xs text-gray-500 text-center">
                Fast delivery · Track live
              </p>
            </div>
          ))}
        </div>
      </section>

      <div className="section-divider" />

      {/* ── 10. REVIEWS ──────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>Customer Love</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-2">
          Don't take our
          <br />
          word for it
        </h2>
        <p className="reveal-up font-body text-sm text-[#3d1a00]/60 mb-8">
          Real words from real customers.
        </p>

        <div className="stagger-parent space-y-4">
          {REVIEWS.map((review, i) => (
            <div
              key={i}
              className="stagger-child bg-white rounded-2xl p-5 border border-[#f0d9b5] shadow-sm"
            >
              <div className="flex items-center justify-between mb-3">
                <div>
                  <p className="font-black text-sm text-[#3d1a00]">
                    {review.name}
                  </p>
                  <p className="text-[10px] text-[#3d1a00]/40 font-medium">
                    {review.location}
                  </p>
                </div>
                <StarRating rating={review.rating} />
              </div>
              <p className="font-body text-sm text-[#3d1a00]/70 leading-relaxed">
                "{review.text}"
              </p>
            </div>
          ))}
        </div>

        {/* Summary stat */}
        <div className="mt-6 bg-[#c17f24] rounded-2xl px-5 py-4 flex items-center justify-between reveal-up">
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

      {/* ── 11. COMMUNITY ────────────────────────────────────────────── */}

      <div className="section-divider" />

      {/* ── 12. FAQs ─────────────────────────────────────────────────── */}
      <section className="px-6 py-10">
        <SectionLabel>FAQ</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold leading-tight mb-8">
          Common questions
        </h2>

        <div className="space-y-3">
          {FAQS.map((faq, i) => (
            <div
              key={i}
              className="reveal-up bg-white rounded-2xl border border-[#f0d9b5] overflow-hidden"
            >
              <button
                onClick={() => toggleFaq(i)}
                className="w-full flex items-center justify-between px-5 py-4 text-left gap-3"
              >
                <p className="font-black text-sm text-[#3d1a00] leading-snug flex-1">
                  {faq.q}
                </p>
                <ChevronRight className="w-4 h-4 text-[#c17f24] shrink-0 transition-transform duration-300" />
              </button>
              <div
                ref={(el) => {
                  faqRefs.current[i] = el;
                }}
                className="overflow-hidden h-0 opacity-0"
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

      {/* ── 13. VISIT US ─────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#3d1a00]">
        <SectionLabel>Visit Us</SectionLabel>
        <h2 className="reveal-up font-display text-3xl font-bold text-[#fff1e3] leading-tight mb-8">
          Come say hello
        </h2>

        <div className="space-y-4">
          <div className="reveal-left flex items-start gap-4 bg-white/5 border border-white/10 rounded-2xl px-5 py-4">
            <MapPin className="w-5 h-5 text-[#c17f24] shrink-0 mt-0.5" />
            <div>
              <p className="text-[#fff1e3] font-black text-sm">Address</p>
              <p className="text-[#c9a87c] text-sm mt-0.5">
                Saheswari Club, Salipur,
                <br />
                Cuttack, Odisha
              </p>
            </div>
          </div>

          <div className="reveal-left flex items-start gap-4 bg-white/5 border border-white/10 rounded-2xl px-5 py-4">
            <Clock className="w-5 h-5 text-[#c17f24] shrink-0 mt-0.5" />
            <div>
              <p className="text-[#fff1e3] font-black text-sm">Opening Hours</p>
              <p className="text-[#c9a87c] text-sm mt-0.5">
                Mon – Sun: 9:00 AM – 10:00 PM
              </p>
              <p className="text-[#c9a87c]/60 text-xs mt-0.5">
                Open all days including holidays
              </p>
            </div>
          </div>

          <div className="reveal-left flex items-start gap-4 bg-white/5 border border-white/10 rounded-2xl px-5 py-4">
            <Phone className="w-5 h-5 text-[#c17f24] shrink-0 mt-0.5" />
            <div>
              <p className="text-[#fff1e3] font-black text-sm">Phone</p>
              <p className="text-[#c9a87c] text-sm mt-0.5">+91 98765 43210</p>
              <p className="text-[#c9a87c]/60 text-xs mt-0.5">
                WhatsApp orders welcome
              </p>
            </div>
          </div>
        </div>

        {/* Map placeholder */}
        <div className="mt-5 reveal-up h-36 bg-white/5 border border-white/10 rounded-2xl flex items-center justify-center">
          <div className="text-center">
            <MapPin className="w-6 h-6 text-[#c17f24] mx-auto mb-2" />
            <p className="text-[#c9a87c] text-xs">Saheswari Club, Salipur</p>
            <p className="text-[#c9a87c]/50 text-[10px] mt-1">
              Tap to open in Maps
            </p>
          </div>
        </div>

        {/* Social links */}
        <div className="mt-5 flex gap-3 reveal-up">
          <button className="flex-1 flex items-center justify-center gap-2 bg-white/10 border border-white/20 rounded-xl py-3 text-[#fff1e3] text-sm font-bold">
            <Share2 className="w-4 h-4" /> Instagram
          </button>
          <button className="flex-1 flex items-center justify-center gap-2 bg-white/10 border border-white/20 rounded-xl py-3 text-[#fff1e3] text-sm font-bold">
            <ThumbsUp className="w-4 h-4" /> Facebook
          </button>
        </div>
      </section>

      {/* ── 14. CTA ──────────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#c17f24]">
        <div className="reveal-up text-center">
          <p className="text-[#3d1a00]/60 text-[10px] font-black tracking-[0.25em] uppercase mb-3">
            Ready?
          </p>
          <h2 className="font-display text-3xl font-black text-[#3d1a00] leading-tight mb-2">
            Hungry yet?
          </h2>
          <p className="text-[#3d1a00]/70 text-sm mb-8 leading-relaxed">
            Order online, visit us, or just follow along — we'd love to feed
            you.
          </p>

          <div className="space-y-3">
            <button className="w-full h-14 bg-[#3d1a00] text-[#fff1e3] font-black text-sm rounded-2xl flex items-center justify-center gap-2 shadow-xl active:scale-95 transition-transform">
              <Utensils className="w-5 h-5" />
              View Our Menu
            </button>
            <button className="w-full h-14 bg-white/30 border-2 border-[#3d1a00]/20 text-[#3d1a00] font-black text-sm rounded-2xl flex items-center justify-center gap-2 active:scale-95 transition-transform">
              <Phone className="w-5 h-5" />
              Call to Order
            </button>
          </div>

          {/* Trust strip */}
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
