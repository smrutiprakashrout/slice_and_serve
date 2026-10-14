"use client";

import { useState } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import Image from "next/image";
import { Star } from "lucide-react";
import { useCartStore } from "@/lib/cart-store";
import useSWR from "swr";
import { fetcher } from "@/lib/fetcher";
import type { Category, MenuItem } from "@/lib/menu-data";

interface MenuApiResponse {
  categories: Category[];
  items: MenuItem[];
}

gsap.registerPlugin(useGSAP);

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
  const { data, error, isLoading, mutate } = useSWR<MenuApiResponse>(
    "/api/menu",
    fetcher,
  );

  const menuItems = data?.items ?? [];
  const categoriesList = data?.categories ?? [];

  // activeCategory — which subcategory chip is active ("all" = none filter)
  const [activeCategory, setActiveCategory] = useState<string>("all");
  // dietFilter — "veg" | "non-veg" | "filter" (all diets) | "all" (full reset)
  const [dietFilter, setDietFilter] = useState<
    "veg" | "non-veg" | "filter" | "all"
  >("all");

  // ── Cart store ────────────────────────────────────────────────────────────
  const items = useCartStore((s) => s.items);
  const addItem = useCartStore((s) => s.addItem);
  const removeOne = useCartStore((s) => s.removeOne);

  const totalItems = items.reduce((s, i) => s + i.qty, 0);
  const getQty = (id: string) => items.find((i) => i.id === id)?.qty ?? 0;

  // ── Handlers with cross-filter logic ─────────────────────────────────────

  // Selecting a subcategory chip → auto-switch diet to "filter" (show all diets)
  const handleCategorySelect = (slug: string) => {
    setActiveCategory(slug);
    // When user picks a subcategory, reset diet to "filter" so they see everything
    if (dietFilter === "all") setDietFilter("filter");
  };

  // Selecting "All" diet tab → full reset: clear subcategory + show everything
  const handleDietSelect = (diet: "veg" | "non-veg" | "filter" | "all") => {
    setDietFilter(diet);
    if (diet === "all") setActiveCategory("all"); // clear subcategory too
  };

  // ── Derived filtering ─────────────────────────────────────────────────────
  // "all" diet tab = full menu (ignore category too, already reset above)
  // "filter" = all diets within selected category
  // "veg"/"non-veg" = filter by type within selected category
  const categoryFiltered = menuItems.filter((item) =>
    activeCategory === "all" ? true : item.categorySlug === activeCategory,
  );
  const filteredMenu = categoryFiltered.filter((item) => {
    if (dietFilter === "all" || dietFilter === "filter") return true;
    return item.type === dietFilter;
  });

  // Counts scoped to current category — shown in each tab
  const vegCount = categoryFiltered.filter((i) => i.type === "veg").length;
  const nonVegCount = categoryFiltered.filter(
    (i) => i.type === "non-veg",
  ).length;
  const filterCount = categoryFiltered.length;
  const allCount = menuItems.length;

  const otherCategories = categoriesList.filter((c) => c.slug !== "all");

  // ── Add to cart with a quick scale animation on the card ──
  const handleAdd = (item: MenuItem) => {
    if (!item.available) return;
    addItem({
      id: item.id,
      name: item.name,
      image: item.image,
      price: item.price,
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
    <main className="font-sans flex flex-col">
      <div className="max-w-md mx-auto w-full bg-[#fff1e3] mt-26 h-full flex flex-col relative shadow-2xl">
        <div data-scroll-container className="flex-1 overflow-y-auto pb-28">
          {/* Menu Title + Diet filter — pill navbar style */}
          <div className="flex items-center justify-between px-4 mb-4 mt-2">
            <p className="font-bold text-xl text-black">Menu</p>

            {/* Pill navbar — dark bar, active tab gets white capsule with label */}
            <div className="flex items-center bg-white rounded-md px-1 py-1 gap-0.5 shadow-lg border-yellow-900/20 border">
              {/* Veg */}
              <button
                type="button"
                onClick={() => handleDietSelect("veg")}
                style={{ WebkitTapHighlightColor: "transparent" }}
                className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 transition-all duration-250 outline-none active:scale-95
                  ${dietFilter === "veg" ? "bg-yellow-900" : ""}`}
              >
                {/* Veg icon — green square dot */}
                <span
                  className={`w-3.5 h-3.5 rounded-sm border-[1.5px] border-green-600 flex items-center justify-center shrink-0
                  ${dietFilter === "veg" ? "bg-white" : "bg-transparent"}`}
                >
                  <span className="w-[5px] h-[5px] rounded-full bg-green-600 block" />
                </span>
                <span
                  className={`font-black text-[11px] whitespace-nowrap
                  ${dietFilter === "veg" ? "text-white" : "text-gray-500"}`}
                >
                  Veg
                </span>
              </button>

              {/* Non-Veg */}
              <button
                type="button"
                onClick={() => handleDietSelect("non-veg")}
                style={{ WebkitTapHighlightColor: "transparent" }}
                className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 transition-all duration-250 outline-none active:scale-95
                  ${dietFilter === "non-veg" ? "bg-yellow-900" : ""}`}
              >
                {/* Non-veg icon — red square dot */}
                <span
                  className={`w-3.5 h-3.5 rounded-sm border-[1.5px] border-red-600 flex items-center justify-center shrink-0
                  ${dietFilter === "non-veg" ? "bg-white" : "bg-transparent"}`}
                >
                  <span className="w-[5px] h-[5px] rounded-full bg-red-600 block" />
                </span>
                <span
                  className={`font-black text-[11px] whitespace-nowrap
                  ${dietFilter === "non-veg" ? "text-white" : "text-gray-500"}`}
                >
                  Non-Veg
                </span>
              </button>

              {/* All — full reset */}
              <button
                type="button"
                onClick={() => handleDietSelect("all")}
                style={{ WebkitTapHighlightColor: "transparent" }}
                className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 transition-all duration-250 outline-none active:scale-95
                  ${dietFilter === "all" ? "bg-yellow-900" : ""}`}
              >
                {/* All icon — 2×2 grid dots */}
                <span className="grid grid-cols-2 gap-[2px] shrink-0">
                  <span className="w-[4px] h-[4px] rounded-full bg-gray-400 block" />
                  <span className="w-[4px] h-[4px] rounded-full bg-gray-400 block" />
                  <span className="w-[4px] h-[4px] rounded-full bg-gray-400 block" />
                  <span className="w-[4px] h-[4px] rounded-full bg-gray-400 block" />
                </span>
                <span
                  className={`font-black text-[11px] whitespace-nowrap
                  ${dietFilter === "all" ? "text-white" : "text-gray-500"}`}
                >
                  All{" "}
                  <span
                    className={
                      dietFilter === "all"
                        ? "font-medium text-gray-100"
                        : "font-medium text-gray-400"
                    }
                  >
                    ({allCount})
                  </span>
                </span>
              </button>
            </div>
          </div>

          {/* Filter status text — no button, just shows when filter mode is active */}
          {dietFilter === "filter" && (
            <p className="px-4 -mt-2 mb-3 text-[11px] font-bold text-yellow-900">
              Filter ({filterCount})
            </p>
          )}

          {/* Menu Grid */}
          <div className="px-6 pb-36">
            {isLoading ? (
              <div className="grid grid-cols-2 gap-4">
                {[1, 2, 3, 4, 5, 6].map((n) => (
                  <div
                    key={`skeleton-${n}`}
                    className="bg-white rounded-2xl overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-gray-100 flex flex-col h-full animate-pulse"
                  >
                    <div className="h-32 bg-gray-200/80 w-full" />
                    <div className="p-3 flex flex-col flex-1 justify-between gap-3">
                      <div>
                        <div className="h-4 bg-gray-200 rounded w-3/4 mb-1.5" />
                        <div className="h-3 bg-gray-100 rounded w-1/2" />
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <div className="h-4 bg-gray-200 rounded w-10" />
                        <div className="h-7 bg-gray-200 rounded-lg w-14" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : error ? (
              <div className="bg-white/80 border border-yellow-900/20 rounded-2xl p-6 text-center shadow-sm my-6">
                <p className="text-sm font-semibold text-gray-800 mb-1">
                  Failed to load menu
                </p>
                <p className="text-xs text-gray-500 mb-4">
                  {error?.message || "Please check your connection and try again."}
                </p>
                <button
                  type="button"
                  onClick={() => mutate()}
                  className="px-4 py-2 bg-yellow-900 text-white text-xs font-bold rounded-lg hover:bg-yellow-800 transition-colors"
                >
                  Try Again
                </button>
              </div>
            ) : menuItems.length === 0 ? (
              <div className="bg-white/80 border border-yellow-900/10 rounded-2xl p-8 text-center shadow-sm my-6">
                <p className="text-gray-700 font-bold text-sm mb-1">
                  Nothing available right now
                </p>
                <p className="text-gray-500 text-xs">
                  Check back soon for delicious new items!
                </p>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-2 gap-4">
                  {filteredMenu.map((item) => {
                    const qty = getQty(item.id);
                    return (
                      <div
                        id={`card-${item.id}`}
                        key={`menu-${item.id}`}
                        className={`bg-white rounded-2xl overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-gray-100 flex flex-col h-full relative ${
                          !item.available ? "opacity-50" : ""
                        }`}
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
                            <div className="absolute inset-0 bg-white/50 backdrop-blur-[2px] flex items-center justify-center z-20 pointer-events-none">
                              <span className="bg-black text-white text-[10px] font-bold px-2 py-1 uppercase tracking-wider rounded-md shadow-sm">
                                Unavailable
                              </span>
                            </div>
                          )}
                        </div>

                        {/* Content */}
                        <div
                          className="p-3 flex flex-col flex-1 justify-between"
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
                                type="button"
                                className="font-bold text-xs px-4 py-1.5 rounded-lg bg-gray-200 text-gray-500 cursor-not-allowed shadow-none"
                              >
                                Unavailable
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
              </>
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
                onClick={() => handleCategorySelect(category.slug)}
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
