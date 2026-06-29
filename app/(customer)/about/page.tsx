"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
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

gsap.registerPlugin(ScrollTrigger);

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
  const pageRef = useRef<HTMLDivElement>(null);
  const tickerRef = useRef<HTMLDivElement>(null);
  const statsRef = useRef<HTMLElement>(null);
  const faqOpenRef = useRef<number | null>(null);
  const faqRefs = useRef<(HTMLDivElement | null)[]>([]);

  // ── FAQ accordion ──────────────────────────────────────────────────────────
  const toggleFaq = (index: number) => {
    const prev = faqOpenRef.current;
    if (prev !== null && prev !== index) {
      const prevEl = faqRefs.current[prev];
      if (prevEl)
        gsap.to(prevEl, {
          height: 0,
          opacity: 0,
          duration: 0.3,
          ease: "power2.inOut",
        });
    }
    const el = faqRefs.current[index];
    if (!el) return;
    if (prev === index) {
      gsap.to(el, {
        height: 0,
        opacity: 0,
        duration: 0.3,
        ease: "power2.inOut",
      });
      faqOpenRef.current = null;
    } else {
      gsap.set(el, { height: "auto", opacity: 1 });
      const fullH = el.scrollHeight;
      gsap.fromTo(
        el,
        { height: 0, opacity: 0 },
        { height: fullH, opacity: 1, duration: 0.4, ease: "power3.out" },
      );
      faqOpenRef.current = index;
    }
  };

  // ── Animations ─────────────────────────────────────────────────────────────
  useEffect(() => {
    const page = pageRef.current;
    if (!page) return;

    // ─────────────────────────────────────────────────────────────────────────
    // CRITICAL RULE: we NEVER start any element at opacity:0 via GSAP on load.
    // All elements are fully visible by default (CSS handles it).
    // GSAP only adds motion on top — translate/scale — never touching opacity
    // on initial load. This means a blank page is impossible.
    //
    // For scroll animations we use a CSS class "anim-hidden" (opacity:0,
    // translateY:30px) applied via JS AFTER the page is already visible,
    // then GSAP animates to visible. This way: if JS fails → page still shows.
    // ─────────────────────────────────────────────────────────────────────────

    // ── 1. HERO — pure motion, no opacity tricks ──────────────────────────
    // const heroTl = gsap.timeline({ delay: 0.1 });
    // heroTl
    //   .from(".anim-hero-img", {
    //     scale: 1.07,
    //     duration: 1.1,
    //     ease: "power2.out",
    //     clearProps: "all",
    //   })
    //   .from(
    //     ".anim-hero-title",
    //     { y: 36, duration: 0.8, ease: "power3.out", clearProps: "all" },
    //     "-=0.6",
    //   )
    //   .from(
    //     ".anim-hero-sub",
    //     { y: 22, duration: 0.7, ease: "power2.out", clearProps: "all" },
    //     "-=0.5",
    //   )
    //   .from(
    //     ".anim-hero-badge",
    //     {
    //       y: 12,
    //       scale: 0.9,
    //       duration: 0.5,
    //       stagger: 0.07,
    //       ease: "back.out(1.8)",
    //       clearProps: "all",
    //     },
    //     "-=0.4",
    //   );

    // // ── 2. TICKER ─────────────────────────────────────────────────────────
    // const ticker = tickerRef.current;
    // if (ticker) {
    //   requestAnimationFrame(() => {
    //     const halfW = ticker.scrollWidth / 2;
    //     if (halfW > 0) {
    //       gsap.to(ticker, {
    //         x: -halfW,
    //         duration: 30,
    //         ease: "none",
    //         repeat: -1,
    //       });
    //     }
    //   });
    // }

    // // ── 3. STATS count-up ────────────────────────────────────────────────
    // if (statsRef.current) {
    //   ScrollTrigger.create({
    //     trigger: statsRef.current,
    //     start: "top 80%",
    //     once: true,
    //     onEnter() {
    //       const statEls = page.querySelectorAll<HTMLElement>(".anim-stat-num");
    //       statEls.forEach((el, i) => {
    //         const end = STATS[i]?.value ?? 0;
    //         const obj = { n: 0 };
    //         gsap.to(obj, {
    //           n: end,
    //           duration: 2,
    //           delay: i * 0.1,
    //           ease: "power2.out",
    //           onUpdate() {
    //             el.textContent = Math.round(obj.n).toLocaleString();
    //           },
    //           onComplete() {
    //             el.textContent = end.toLocaleString();
    //           },
    //         });
    //       });
    //     },
    //   });
    // }

    // ── 4. SCROLL REVEALS — hide via JS first, then reveal ───────────────
    // We only hide elements AFTER checking the page rendered (inside useEffect).
    // Any failure leaves them fully visible — no blank page ever.

    // Gather all scroll-animated elements
    // const revealEls = page.querySelectorAll<HTMLElement>(".anim-up");
    // const revealLeft = page.querySelectorAll<HTMLElement>(".anim-left");
    // const revealScale = page.querySelectorAll<HTMLElement>(".anim-scale");
    // const hygieneEls = page.querySelectorAll<HTMLElement>(".anim-hygiene");
    // const headingEls = page.querySelectorAll<HTMLElement>(".anim-heading");

    // // Step 1: hide them all now (DOM is ready, page already painted once)
    // gsap.set(revealEls, { y: 32, opacity: 0 });
    // gsap.set(revealLeft, { x: -28, opacity: 0 });
    // gsap.set(revealScale, { scale: 0.88, opacity: 0 });
    // gsap.set(hygieneEls, { x: -22, opacity: 0 });
    // gsap.set(headingEls, { y: 24, opacity: 0 });

    // // Step 2: animate each to visible on scroll
    // // Use toggleActions "play none none none" with once:true so elements
    // // already in the viewport on load also get revealed immediately.
    // revealEls.forEach((el, i) => {
    //   gsap.to(el, {
    //     y: 0,
    //     opacity: 1,
    //     duration: 0.7,
    //     ease: "power3.out",
    //     scrollTrigger: {
    //       trigger: el,
    //       start: "top 95%",
    //       once: true,
    //     },
    //   });
    // });

    // revealLeft.forEach((el) => {
    //   gsap.to(el, {
    //     x: 0,
    //     opacity: 1,
    //     duration: 0.65,
    //     ease: "power3.out",
    //     scrollTrigger: { trigger: el, start: "top 95%", once: true },
    //   });
    // });

    // revealScale.forEach((el) => {
    //   gsap.to(el, {
    //     scale: 1,
    //     opacity: 1,
    //     duration: 0.55,
    //     ease: "back.out(1.5)",
    //     scrollTrigger: { trigger: el, start: "top 95%", once: true },
    //   });
    // });

    // hygieneEls.forEach((el, i) => {
    //   gsap.to(el, {
    //     x: 0,
    //     opacity: 1,
    //     duration: 0.5,
    //     ease: "power3.out",
    //     delay: i * 0.05,
    //     scrollTrigger: { trigger: el, start: "top 95%", once: true },
    //   });
    // });

    // headingEls.forEach((el) => {
    //   gsap.to(el, {
    //     y: 0,
    //     opacity: 1,
    //     duration: 0.7,
    //     ease: "power3.out",
    //     scrollTrigger: { trigger: el, start: "top 95%", once: true },
    //   });
    // });

    // // ── 5. CARD GRIDS ────────────────────────────────────────────────────
    // // IMPORTANT: stagger + scrollTrigger in one gsap.to() call is broken in
    // // GSAP 3 — only the first item animates, the rest stay opacity:0 forever.
    // // Fix: each card gets its own individual tween + its own ScrollTrigger.
    // page.querySelectorAll<HTMLElement>(".anim-grid").forEach((grid) => {
    //   const cards = Array.from(
    //     grid.querySelectorAll<HTMLElement>(".anim-card"),
    //   );
    //   if (!cards.length) return;
    //   gsap.set(cards, { y: 28, opacity: 0 });
    //   cards.forEach((card, i) => {
    //     gsap.to(card, {
    //       y: 0,
    //       opacity: 1,
    //       duration: 0.55,
    //       delay: i * 0.08,
    //       ease: "power3.out",
    //       scrollTrigger: { trigger: grid, start: "top 88%", once: true },
    //     });
    //   });
    // });

    // // Cleanup
    // return () => {
    //   ScrollTrigger.getAll().forEach((t) => t.kill());
    // };
  }, []);

  return (
    <div ref={pageRef} className="bg-[#fff1e3] font-sans text-[#3d1a00] pb-32">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;900&display=swap');
        .font-display    { font-family: 'Playfair Display', Georgia, serif; }
        .font-body       { font-family: 'Inter', system-ui, sans-serif; }
        .section-divider { height:1px; background:linear-gradient(to right,transparent,#c17f2440,transparent); margin:0 1.5rem; }
        .ticker-wrap     { overflow:hidden; }
        .ticker-inner    { display:flex; gap:2.5rem; white-space:nowrap; will-change:transform; width:max-content; }
      `}</style>

      {/* ── HERO ──────────────────────────────────────────────────────── */}
      <section className="relative min-h-[70vh] flex flex-col px-6 pb-10 overflow-hidden">
        <div className="relative z-10 mt-24">
          <div className="anim-hero-img rounded-2xl w-full h-[30vh] overflow-hidden">
            <Image
              src="/images/shop.png"
              alt="Slice & Serve"
              width={900}
              height={900}
              className="w-full h-full object-cover"
              priority
            />
          </div>

          <h1 className="anim-hero-title font-display text-4xl font-black text-yellow-900 leading-[1.08] mb-4 pt-6">
            Fresh Food.
            <br />
            Warm
            <br />
            Hospitality.
          </h1>

          <p className="anim-hero-sub font-body text-yellow-700 text-base leading-relaxed mb-6 max-w-xs">
            Authentic flavours made with fresh ingredients, cooked to order —
            every single day.
          </p>

          <div className="flex gap-2 flex-wrap">
            {["🛡️ FSSAI Certified", "✨ No Preservatives", "🛵 On Zomato"].map(
              (b) => (
                <span
                  key={b}
                  className="anim-hero-badge bg-white/10 border border-yellow-900/20 text-yellow-900 text-[11px] font-bold px-3 py-1.5 rounded-full"
                >
                  {b}
                </span>
              ),
            )}
          </div>
        </div>

        <div className="absolute bottom-4 right-6 flex flex-col items-center gap-1 opacity-50">
          <p className="text-[9px] tracking-widest uppercase text-[#3d1a00]">
            Scroll
          </p>
          <ChevronDown className="w-4 h-4 text-[#3d1a00] animate-bounce" />
        </div>
      </section>

      {/* ── TICKER ────────────────────────────────────────────────────── */}
      <div className="ticker-wrap bg-[#c17f24] py-3">
        <div ref={tickerRef} className="ticker-inner">
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
      <section ref={statsRef} className="bg-[#3d1a00] px-6 py-8">
        <div className="grid grid-cols-2 gap-6">
          {STATS.map((stat, i) => (
            <div key={i} className="text-center">
              <p className="font-display text-4xl font-black text-[#c17f24] leading-none">
                <span className="anim-stat-num">0</span>
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-2">
          What we stand for
        </h2>
        <p className="anim-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          These aren&apos;t just words on a wall — they&apos;re the decisions we
          make in the kitchen every single day.
        </p>
        <div className="anim-grid grid grid-cols-1 gap-4">
          {VALUES.map((v, i) => {
            const Icon = v.icon;
            return (
              <div
                key={i}
                className="anim-card flex gap-4 items-start bg-white rounded-2xl p-4 border border-[#f0d9b5] shadow-sm"
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-8">
          The people behind
          <br />
          every bite
        </h2>
        <div className="anim-grid space-y-5">
          {TEAM.map((person, i) => (
            <div
              key={i}
              className="anim-card bg-[#3d1a00] rounded-2xl p-5 text-[#fff1e3]"
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-8">
          The Slice &amp; Serve
          <br />
          difference
        </h2>
        <div className="anim-grid grid grid-cols-2 gap-3">
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
              className="anim-card bg-[#fff1e3] rounded-2xl p-4 text-center border border-[#f0d9b5]"
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-2">
          Our kitchen is as
          <br />
          clean as your home
        </h2>
        <p className="anim-up font-body text-sm text-[#3d1a00]/60 mb-8 leading-relaxed">
          Every meal we serve carries our name — so hygiene is non-negotiable,
          not optional.
        </p>
        <div className="space-y-3">
          {HYGIENE.map((item, i) => (
            <div
              key={i}
              className="anim-hygiene flex items-center gap-3 bg-white rounded-xl px-4 py-3 border border-[#f0d9b5]"
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
        <div className="anim-up mt-6 bg-[#3d1a00] rounded-2xl px-5 py-4 flex items-center gap-4">
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
        <h2 className="anim-heading font-display text-3xl font-bold text-yellow-900 leading-tight mb-2">
          Quality starts at
          <br />
          the source
        </h2>
        <p className="anim-up font-body text-sm text-yellow-800 mb-8 leading-relaxed">
          We never take shortcuts with ingredients. Period.
        </p>
        <div className="anim-grid grid grid-cols-1 gap-3">
          {INGREDIENTS.map((item, i) => (
            <div
              key={i}
              className="anim-card flex items-center gap-4 bg-[#3d1a00]/20 border border-[#3d1a00]/10 rounded-xl px-4 py-3"
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
        <h2 className="anim-heading font-display text-2xl font-bold mb-6">
          Available on
        </h2>
        <div className="anim-grid flex gap-4">
          <div className="anim-card flex-1 bg-red-50 border border-red-100 rounded-2xl p-5 flex flex-col items-center gap-2">
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-2">
          Don&apos;t take our
          <br />
          word for it
        </h2>
        <p className="anim-up font-body text-sm text-[#3d1a00]/60 mb-8">
          Real words from real customers.
        </p>
        <div className="anim-grid space-y-4">
          {REVIEWS.map((r, i) => (
            <div
              key={i}
              className="anim-card bg-white rounded-2xl p-5 border border-[#f0d9b5] shadow-sm"
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
        <div className="anim-scale mt-6 bg-[#c17f24] rounded-2xl px-5 py-4 flex items-center justify-between">
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
        <h2 className="anim-heading font-display text-3xl font-bold leading-tight mb-8">
          Common questions
        </h2>
        <div className="anim-grid space-y-3">
          {FAQS.map((faq, i) => (
            <div
              key={i}
              className="anim-card bg-white rounded-2xl border border-[#f0d9b5] overflow-hidden"
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
                style={{ height: 0, opacity: 0, overflow: "hidden" }}
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
        <h2 className="anim-heading font-display text-3xl font-bold text-[#fff1e3] leading-tight mb-8">
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
                "Mon – Sun: 9:00 AM – 10:00 PM",
                "Open all days including holidays",
              ],
            },
            {
              Icon: Phone,
              title: "Phone",
              lines: ["+91 98765 43210", "WhatsApp orders welcome"],
            },
          ].map(({ Icon, title, lines }, i) => (
            <div
              key={i}
              className="anim-left flex items-start gap-4 bg-white/5 border border-white/10 rounded-2xl px-5 py-4"
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
        <div className="anim-up mt-5 h-36 bg-white/5 border border-white/10 rounded-2xl flex items-center justify-center">
          <div className="text-center">
            <MapPin className="w-6 h-6 text-[#c17f24] mx-auto mb-2" />
            <p className="text-[#c9a87c] text-xs">Saheswari Club, Salipur</p>
            <p className="text-[#c9a87c]/50 text-[10px] mt-1">
              Tap to open in Maps
            </p>
          </div>
        </div>
        <div className="mt-5 flex gap-3">
          <button className="anim-scale flex-1 flex items-center justify-center gap-2 bg-white/10 border border-white/20 rounded-xl py-3 text-[#fff1e3] text-sm font-bold">
            <Share2 className="w-4 h-4" /> Instagram
          </button>
          <button className="anim-scale flex-1 flex items-center justify-center gap-2 bg-white/10 border border-white/20 rounded-xl py-3 text-[#fff1e3] text-sm font-bold">
            <ThumbsUp className="w-4 h-4" /> Facebook
          </button>
        </div>
      </section>

      {/* ── CTA ───────────────────────────────────────────────────────── */}
      <section className="px-6 py-10 bg-[#c17f24]">
        <div className="anim-up text-center">
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
            <button className="w-full h-14 bg-[#3d1a00] text-[#fff1e3] font-black text-sm rounded-2xl flex items-center justify-center gap-2 shadow-xl active:scale-95 transition-transform">
              <Utensils className="w-5 h-5" /> View Our Menu
            </button>
            <button className="w-full h-14 bg-white/30 border-2 border-[#3d1a00]/20 text-[#3d1a00] font-black text-sm rounded-2xl flex items-center justify-center gap-2 active:scale-95 transition-transform">
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
