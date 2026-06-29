"use client";

import { useState } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import Image from "next/image";
import { Star } from "lucide-react";
import { useCartStore } from "@/lib/cart-store";

gsap.registerPlugin(useGSAP);

// ─── Types & Data (unchanged from your file) ──────────────────────────────────

interface Category {
  id: string;
  name: string;
  slug: string;
  icon: string;
}

interface MenuItem {
  id: string;
  name: string;
  subtitle: string;
  price: number;
  rating: number;
  categorySlug: string;
  type: "veg" | "non-veg";
  featured: boolean;
  image: string;
  available: boolean;
}

const CATEGORIES: Category[] = [
  { id: "1", name: "All", slug: "all", icon: "" },
  { id: "2", name: "Sandwitch", slug: "sandwitch", icon: "🥪" },
  { id: "3", name: "Burger", slug: "burger", icon: "🍔" },
  { id: "4", name: "Staters", slug: "staters", icon: "🍟" },
  { id: "5", name: "Drinks", slug: "drinks", icon: "🥤" },
];

const MOCK_MENU: MenuItem[] = [
  // BURGERS
  {
    id: "b1",
    name: "Chicken Burger",
    subtitle: "Classic chicken patty",
    price: 79,
    rating: 4.5,
    categorySlug: "burger",
    type: "non-veg",
    featured: true,
    image: "/images/burger.jpg",
    available: true,
  },
  // SANDWICHES
  {
    id: "s1",
    name: "Chicken 65 Sandwich",
    subtitle: "Spicy Non-Veg",
    price: 79,
    rating: 4.8,
    categorySlug: "sandwitch",
    type: "non-veg",
    featured: true,
    image: "/images/65_sandwitch.jpg",
    available: true,
  },
  {
    id: "s2",
    name: "Chilli Chicken Sandwich",
    subtitle: "Non-Veg",
    price: 75,
    rating: 4.6,
    categorySlug: "sandwitch",
    type: "non-veg",
    featured: false,
    image: "/images/chilli_chicken_sand.jpg",
    available: true,
  },
  {
    id: "s3",
    name: "Chicken Sandwich",
    subtitle: "Classic Non-Veg",
    price: 69,
    rating: 4.4,
    categorySlug: "sandwitch",
    type: "non-veg",
    featured: false,
    image: "/images/chicken_sand.jpg",
    available: true,
  },
  {
    id: "s4",
    name: "Egg Sandwich",
    subtitle: "Non-Veg",
    price: 59,
    rating: 4.3,
    categorySlug: "sandwitch",
    type: "non-veg",
    featured: false,
    image: "/images/egg_sand.jpg",
    available: false,
  },
  {
    id: "s5",
    name: "Chilli Mushroom Sandwich",
    subtitle: "Spicy Veg",
    price: 65,
    rating: 4.5,
    categorySlug: "sandwitch",
    type: "veg",
    featured: true,
    image: "/images/Chilli_mushroom_sand.jpg",
    available: true,
  },
  {
    id: "s6",
    name: "Mushroom Manchurian Sandwich",
    subtitle: "Indo-Chinese Veg",
    price: 65,
    rating: 4.7,
    categorySlug: "sandwitch",
    type: "veg",
    featured: false,
    image: "/images/Mushroom_sand.jpg",
    available: true,
  },
  {
    id: "s7",
    name: "Cheese & Corn Sandwich",
    subtitle: "Veg",
    price: 59,
    rating: 4.6,
    categorySlug: "sandwitch",
    type: "veg",
    featured: false,
    image: "/images/cheese_and_corn_sand.jpg",
    available: true,
  },
  {
    id: "s8",
    name: "Veg Sandwich with Cheese",
    subtitle: "Veg",
    price: 49,
    rating: 4.4,
    categorySlug: "sandwitch",
    type: "veg",
    featured: false,
    image: "/images/Veg_Sand.jpg",
    available: true,
  },
  {
    id: "s9",
    name: "Nutella Sandwich",
    subtitle: "Sweet Veg",
    price: 85,
    rating: 4.9,
    categorySlug: "sandwitch",
    type: "veg",
    featured: false,
    image: "/images/nutella_sandwich.jpg",
    available: true,
  },
  {
    id: "s10",
    name: "Paneer Sandwich",
    subtitle: "Veg",
    price: 79,
    rating: 4.7,
    categorySlug: "sandwitch",
    type: "veg",
    featured: false,
    image: "/images/Panner_sandwitch.jpg",
    available: true,
  },
  // STARTERS
  {
    id: "st1",
    name: "Chicken Lollipop",
    subtitle: "04 PC | Non-Veg",
    price: 129,
    rating: 4.9,
    categorySlug: "staters",
    type: "non-veg",
    featured: true,
    image: "/images/snacks/Chicken_Lollipop.jpg",
    available: true,
  },
  {
    id: "st2",
    name: "Chicken Kabab",
    subtitle: "10 PC | Non-Veg",
    price: 75,
    rating: 4.7,
    categorySlug: "staters",
    type: "non-veg",
    featured: false,
    image: "/images/snacks/chicken_kabab.jpg",
    available: true,
  },
  {
    id: "st3",
    name: "Finger Chicken",
    subtitle: "12 PC | Non-Veg",
    price: 79,
    rating: 4.5,
    categorySlug: "staters",
    type: "non-veg",
    featured: false,
    image: "/images/snacks/finger_chicken.jpg",
    available: true,
  },
  {
    id: "st4",
    name: "Chicken Pakoda",
    subtitle: "06 PC | Non-Veg",
    price: 69,
    rating: 4.6,
    categorySlug: "staters",
    type: "non-veg",
    featured: false,
    image: "/images/snacks/chicken_pocoda.jpg",
    available: true,
  },
  {
    id: "st5",
    name: "Finger Paneer",
    subtitle: "12 PC | Veg",
    price: 85,
    rating: 4.7,
    categorySlug: "staters",
    type: "veg",
    featured: false,
    image: "/images/snacks/veg/finger_panner.jpg",
    available: true,
  },
  {
    id: "st6",
    name: "Paneer Kabab",
    subtitle: "10 PC | Veg",
    price: 85,
    rating: 4.8,
    categorySlug: "staters",
    type: "veg",
    featured: false,
    image: "/images/snacks/veg/paneer_kabab.jpg",
    available: true,
  },
  {
    id: "st7",
    name: "Crispy Corn",
    subtitle: "Veg",
    price: 69,
    rating: 4.5,
    categorySlug: "staters",
    type: "veg",
    featured: false,
    image: "/images/snacks/veg/Crispy_Corn.jpg",
    available: true,
  },
  {
    id: "st8",
    name: "French Fries",
    subtitle: "Veg",
    price: 59,
    rating: 4.4,
    categorySlug: "staters",
    type: "veg",
    featured: false,
    image: "/images/snacks/veg/Fries.jpg",
    available: true,
  },
  // DRINKS
  {
    id: "d1",
    name: "Blue Angel",
    subtitle: "Refreshing mocktail",
    price: 49,
    rating: 4.6,
    categorySlug: "drinks",
    type: "veg",
    featured: false,
    image: "/images/drink/blue_angel.jpg",
    available: true,
  },
  {
    id: "d2",
    name: "Peach Ice Tea",
    subtitle: "Chilled sweet tea",
    price: 49,
    rating: 4.7,
    categorySlug: "drinks",
    type: "veg",
    featured: true,
    image: "/images/drink/peach_iced_tea.jpg",
    available: true,
  },
  {
    id: "d3",
    name: "Lemon Ice Tea",
    subtitle: "Classic citrus tea",
    price: 49,
    rating: 4.5,
    categorySlug: "drinks",
    type: "veg",
    featured: false,
    image: "/images/drink/lemon_ice_tea.jpg",
    available: true,
  },
  {
    id: "d4",
    name: "Watermelon Sparkler",
    subtitle: "Fizzy summer cooler",
    price: 49,
    rating: 4.8,
    categorySlug: "drinks",
    type: "veg",
    featured: false,
    image: "/images/drink/Watermelon_Sparkling.png",
    available: false,
  },
];

// ─── Veg/Non-Veg icon (unchanged) ─────────────────────────────────────────────

const DietIcon = ({ type }: { type: "veg" | "non-veg" }) => {
  const isVeg = type === "veg";
  return (
    <div
      className={`flex items-center justify-center w-4 h-4 border-[1.5px] rounded-sm bg-white shrink-0 ${isVeg ? "border-green-600" : "border-red-600"}`}
    >
      <div
        className={`w-[6px] h-[6px] rounded-full ${isVeg ? "bg-green-600" : "bg-red-600"}`}
      />
    </div>
  );
};

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function MobileMenu() {
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const [dietFilter, setDietFilter] = useState<"all" | "veg" | "non-veg">(
    "all",
  );

  // ── Cart store — subscribe to items array directly so UI re-renders on every change ──
  const items = useCartStore((s) => s.items); // ← reactive value, triggers re-render
  const addItem = useCartStore((s) => s.addItem);
  const removeOne = useCartStore((s) => s.removeOne);

  // Derived inline — always in sync with items
  const totalItems = items.reduce((s, i) => s + i.qty, 0);
  const getQty = (id: string) => items.find((i) => i.id === id)?.qty ?? 0;

  // Category sub-filter (unchanged) then diet filter layered on top
  const categoryFiltered = MOCK_MENU.filter((item) =>
    activeCategory === "all" ? true : item.categorySlug === activeCategory,
  );
  const filteredMenu = categoryFiltered.filter((item) =>
    dietFilter === "all" ? true : item.type === dietFilter,
  );

  // Counts scoped to current category selection for tab labels
  const vegCount = categoryFiltered.filter((i) => i.type === "veg").length;
  const nonVegCount = categoryFiltered.filter(
    (i) => i.type === "non-veg",
  ).length;
  const allCount = categoryFiltered.length;

  const otherCategories = CATEGORIES.filter((c) => c.slug !== "all");
  const isAllActive = activeCategory === "all";

  // ── Add to cart with a quick scale animation on the card ──
  const handleAdd = (item: MenuItem) => {
    addItem({
      id: item.id,
      name: item.name,
      image: item.image,
      price: item.price, // ← real price from MOCK_MENU
      type: item.type === "veg" ? "veg" : "nonveg",
    });
    // Micro-animation: briefly scale the card
    const card = document.getElementById(`card-${item.id}`);
    if (card)
      gsap.fromTo(
        card,
        { scale: 0.96 },
        { scale: 1, duration: 0.25, ease: "back.out(3)" },
      );
  };

  return (
    <main className="bg-[#ffffff] font-sans h-dvh flex flex-col">
      <div className="max-w-md mx-auto w-full bg-[#fff1e3] mt-26 h-full flex flex-col relative shadow-2xl">
        <div className="flex-1 overflow-y-auto pb-28">
          {/* Menu Title + Veg / Non-Veg / All tab switcher */}
          <div className="flex items-center justify-between px-6 mb-4 mt-2">
            <p className="font-bold text-xl text-black">Menu</p>

            {/* 3-tab pill — Veg · Non-Veg · All */}
            <div className="flex items-center bg-white border-2 border-yellow-900 rounded-xl overflow-hidden shadow-sm">
              {/* Veg tab */}
              <button
                type="button"
                onClick={() => setDietFilter("veg")}
                className={`flex items-center gap-1 h-8 px-3 font-bold text-xs transition-all duration-200 outline-none
                  ${
                    dietFilter === "veg"
                      ? "bg-green-600 text-white"
                      : "bg-white text-yellow-950"
                  }`}
                style={{ WebkitTapHighlightColor: "transparent" }}
              >
                {/* Indian green veg dot */}
                {/*<span className="w-3 h-3 rounded-sm border border-green-600 flex items-center justify-center bg-white shrink-0">
                  <span className="w-[5px] h-[5px] rounded-full bg-green-600 block" />
                </span>*/}
                <span>Veg</span>
                {/*<span className="text-[10px] opacity-70">({vegCount})</span>*/}
              </button>

              {/* Divider */}
              <div className="w-px h-5 bg-yellow-900/30" />

              {/* Non-Veg tab */}
              <button
                type="button"
                onClick={() => setDietFilter("non-veg")}
                className={`flex items-center gap-1 h-8 px-3 font-bold text-xs transition-all duration-200 outline-none
                  ${
                    dietFilter === "non-veg"
                      ? "bg-red-600 text-white"
                      : "bg-white text-yellow-950"
                  }`}
                style={{ WebkitTapHighlightColor: "transparent" }}
              >
                {/* Indian red non-veg dot */}
                {/*<span className="w-3 h-3 rounded-sm border border-red-600 flex items-center justify-center bg-white shrink-0">
                  <span className="w-[5px] h-[5px] rounded-full bg-red-600 block" />
                </span>*/}
                <span>Non-Veg</span>
                {/*<span className="text-[10px] opacity-70">({nonVegCount})</span>*/}
              </button>

              {/* Divider */}
              <div className="w-px h-5 bg-yellow-900/30" />

              {/* All tab */}
              <button
                type="button"
                onClick={() => setDietFilter("all")}
                className={`flex items-center gap-1 h-8 px-3 font-bold text-xs transition-all duration-200 outline-none
                  ${
                    dietFilter === "all"
                      ? "bg-yellow-500 text-gray-900"
                      : "bg-white text-gray-700"
                  }`}
                style={{ WebkitTapHighlightColor: "transparent" }}
              >
                <span>All</span>
                <span className="text-[10px] opacity-70">({allCount})</span>
              </button>
            </div>
          </div>

          {/* Menu Grid */}
          <div className="px-6 pb-36">
            <div className="grid grid-cols-2 gap-4">
              {filteredMenu.map((item) => {
                const qty = getQty(item.id);
                return (
                  <div
                    id={`card-${item.id}`}
                    key={`menu-${item.id}`}
                    className="bg-white rounded-2xl overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-gray-100 flex flex-col h-full relative"
                  >
                    {/* Image */}
                    <div className="h-32 bg-gray-100 relative w-full flex items-center justify-center shrink-0 overflow-hidden">
                      {item.image ? (
                        <Image
                          src={item.image}
                          alt={item.name}
                          width={100}
                          height={100}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <span className="text-xs text-gray-400 font-bold tracking-widest uppercase">
                          Image
                        </span>
                      )}
                      <div className="absolute top-2 right-2 bg-white rounded p-[3px] shadow-sm z-10">
                        <DietIcon type={item.type} />
                      </div>
                      {!item.available && (
                        <div className="absolute inset-0 bg-white/50 backdrop-blur-[2px] flex items-center justify-center z-20">
                          <span className="bg-black text-white text-[10px] font-bold px-2 py-1 uppercase tracking-wider rounded-md shadow-sm">
                            Out of Stock
                          </span>
                        </div>
                      )}
                    </div>

                    {/* Content */}
                    <div
                      className={`p-3 flex flex-col flex-1 justify-between ${!item.available ? "opacity-75" : ""}`}
                    >
                      <div>
                        <h3 className="font-semibold text-[15px] text-gray-900 leading-tight mb-[2px]">
                          {item.name}
                        </h3>
                        <p className="text-[11px] text-gray-500 truncate">
                          {item.subtitle}
                        </p>
                      </div>

                      {/* Price + Add/Qty stepper */}
                      <div className="flex items-center justify-between mt-3 pt-1">
                        <span className="font-extrabold text-sm text-gray-900">
                          ₹{item.price}
                        </span>

                        {/* Add → "Added ✓" on tap, inline stepper for qty */}
                        {!item.available ? (
                          <button
                            disabled
                            className="font-bold text-xs px-4 py-1.5 rounded-lg bg-gray-200 text-gray-500 cursor-not-allowed shadow-none"
                          >
                            Sold Out
                          </button>
                        ) : qty > 0 ? (
                          <div className="flex flex-col items-end gap-1">
                            {/* "Added" pill — white bg, black text, yellow border */}
                            <div className="flex items-center gap-1 bg-white border-2 border-yellow-900 rounded-lg px-2 py-1">
                              <span className="font-black text-[11px] text-black">
                                Added ✓
                              </span>
                            </div>
                            {/* Qty stepper below */}
                            <div className="flex items-center gap-1">
                              <button
                                onClick={() => removeOne(item.id)}
                                className="w-5 h-5 rounded-md bg-yellow-900 text-white font-black text-sm flex items-center justify-center active:scale-90 transition-transform"
                              >
                                −
                              </button>
                              <span className="font-black text-xs text-gray-900 w-4 text-center">
                                {qty}
                              </span>
                              <button
                                onClick={() => handleAdd(item)}
                                className="w-5 h-5 rounded-md bg-yellow-900 text-white font-black text-sm flex items-center justify-center active:scale-90 transition-transform"
                              >
                                +
                              </button>
                            </div>
                          </div>
                        ) : (
                          <button
                            onClick={() => handleAdd(item)}
                            className="font-bold text-xs px-4 py-1.5 rounded-lg bg-[#fdc647] text-black hover:bg-yellow-400 transition-all duration-200 shadow-sm active:scale-95"
                          >
                            Add
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {filteredMenu.length === 0 && (
              <div className="text-center py-10">
                <p className="text-gray-500 font-medium text-sm">
                  No items found in this category.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Category filter bar (unchanged) */}
        <div className="fixed bottom-0 w-full max-w-md h-42 bg-[#fff1e3] z-50 shadow-[0_-6px_12px_rgba(0,0,0,0.12)] flex justify-center">
          <p className="text-black/50 font-medium text-xs p-2">
            Whats on your mind pick one item to fliter
          </p>
        </div>
        <div className="flex flex-wrap fixed bottom-20 w-full max-w-md justify-center gap-3 px-4 py-2 z-50">
          {otherCategories.map((category) => {
            const isActive = activeCategory === category.slug;
            return (
              <button
                key={category.id}
                type="button"
                onClick={() => setActiveCategory(category.slug)}
                className={`flex items-center justify-center gap-2 rounded-xl font-bold text-sm h-12 transition-all duration-300 shadow-sm outline-none ${
                  isActive
                    ? "bg-yellow-900 text-white border-2 border-yellow-900 px-5"
                    : "bg-white text-black border border-gray-200 w-12"
                }`}
                style={{ WebkitTapHighlightColor: "transparent" }}
              >
                <span className="text-lg leading-none flex items-center justify-center">
                  {category.icon}
                </span>
                {isActive && <span>{category.name}</span>}
              </button>
            );
          })}
        </div>
      </div>
    </main>
  );
}
