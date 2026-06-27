"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  MapPin,
  ChevronDown,
  Home,
  Compass,
  Heart,
  ShoppingCart,
  User,
  Star,
} from "lucide-react";
import { log } from "console";

gsap.registerPlugin(useGSAP);

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
}

const CATEGORIES: Category[] = [
  { id: "1", name: "All", slug: "all", icon: "🍽️" },
  { id: "2", name: "Sandwitch", slug: "sandwitch", icon: "🥪" },
  { id: "3", name: "Burger", slug: "burger", icon: "🍔" },
  { id: "4", name: "Staters", slug: "staters", icon: "🍟" },
  { id: "5", name: "Drinks", slug: "drinks", icon: "🥤" },
];

const MOCK_MENU: MenuItem[] = [
  {
    id: "m1",
    name: "Truffle Arancini",
    subtitle: "Crispy risotto balls",
    price: 12.0,
    rating: 4.8,
    categorySlug: "pizza",
  },
  {
    id: "m2",
    name: "Wagyu Ribeye",
    subtitle: "8oz grass-fed wagyu",
    price: 45.0,
    rating: 4.9,
    categorySlug: "burger",
  },
  {
    id: "m3",
    name: "Miso Glazed Cod",
    subtitle: "Pan-seared cod",
    price: 32.0,
    rating: 4.7,
    categorySlug: "all",
  },
  {
    id: "m4",
    name: "Dark Choco Tart",
    subtitle: "70% cocoa tart",
    price: 9.0,
    rating: 4.9,
    categorySlug: "drinks",
  },
];

export default function MobileMenu() {
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const listRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      gsap.fromTo(
        ".food-card",
        { x: 30, opacity: 0 },
        {
          x: 0,
          opacity: 1,
          duration: 0.4,
          stagger: 0.1,
          ease: "power2.out",
          clearProps: "all",
        },
      );
    },
    { dependencies: [activeCategory], scope: listRef },
  );

  return (
    <main className="bg-white font-sans h-dvh flex flex-col">
      <div className="max-w-md mx-auto w-full bg-[#fff1e3] h-full flex flex-col">
        {/* SCROLLABLE CONTENT */}
        <div className="flex-1 overflow-y-auto">
          {/* Top Bar */}
          <header className="px-6 pt-4 pb-4 flex justify-between items-center">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-yellow-800 rounded-sm flex items-center justify-center">
                <User className="w-5 h-5 text-white" />
              </div>
              <div className="flex flex-col">
                <span className="text-xs text-gray-500 font-medium">
                  Location
                </span>
                <div className="flex items-center gap-1">
                  <MapPin className="w-4 h-4 text-black" />
                  <span className="text-sm font-bold text-black">
                    Saheswari Club, Salipur
                  </span>
                  <ChevronDown className="w-4 h-4 text-gray-500" />
                </div>
              </div>
            </div>
            <button className="w-10 h-10 bg-white rounded-md flex items-center justify-center relative">
              <ShoppingCart className="w-6 h-6 text-gray-400" />
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white" />
            </button>
          </header>

          {/* Popular Dishes */}
          <div ref={listRef}>
            <div className="px-6 mb-4">
              <h2 className="text-lg font-bold text-black">Popular Dishes</h2>
            </div>
            <div className="flex flex-row flex-nowrap gap-4 overflow-x-auto px-6 pb-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {MOCK_MENU.map((item, index) => {
                const isDark = index % 2 === 0;
                return (
                  <div
                    key={item.id}
                    className={`food-card relative rounded-xl p-6 h-32 w-72 shrink-0 overflow-hidden ${
                      isDark ? "bg-yellow-500" : "bg-yellow-900"
                    } text-white`}
                  >
                    <div className="relative z-10 flex flex-col justify-center h-full">
                      <h3 className="text-xl font-black mb-1">{item.name}</h3>
                      <div className="flex items-center gap-4">
                        <div className="flex items-center gap-1">
                          <Star
                            className={`w-4 h-4 fill-current ${isDark ? "text-yellow-800" : "text-yellow-400"}`}
                          />
                          <span className="font-bold text-sm">
                            {item.rating}
                          </span>
                        </div>
                        <div
                          className={`py-1 px-3 rounded-lg ${isDark ? "bg-yellow-900" : "bg-yellow-400"}`}
                        >
                          <p
                            className={`font-extrabold ${isDark ? "text-white" : "text-gray-700"}`}
                          >
                            ₹{item.price}/-
                          </p>
                        </div>
                      </div>
                    </div>
                    <div className="pointer-events-none absolute -right-8 top-1/2 -translate-y-1/2 w-40 h-40 rounded-full bg-white/10 flex items-center justify-center">
                      <span className="text-xs font-bold opacity-50 text-black">
                        IMAGE
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
          <div className="">
            <p className="font-bold text-xl px-6 mb-4 text-black">Menu</p>
            <button
              className="bg-red-500 absolute z-50"
              onClick={() => {
                alert("button clicked");
              }}
            >
              click button
            </button>
          </div>
        </div>

        {/* BOTTOM SECTION — natural flow, no fixed/absolute */}
        <div className="shrink-0 bg-[#fff1e3]">
          {/* Categories */}
          <div className="flex justify-center gap-3 px-4 py-3">
            {CATEGORIES.map((category) => {
              const isActive = activeCategory === category.slug;
              return (
                <button
                  key={category.id}
                  type="button"
                  onClick={() => {
                    console.log("clicked");
                    setActiveCategory(category.slug);
                  }}
                  className={`
                    flex items-center justify-center gap-2
                    rounded-xl font-bold text-sm
                    min-w-[48px] h-12 touch-auto
                    transition-colors duration-150
                    ${
                      isActive
                        ? "bg-yellow-900 text-white border-2 border-yellow-900 px-5"
                        : "bg-white text-black border border-gray-200 w-12"
                    }
                  `}
                >
                  <span className="text-lg leading-none">{category.icon}</span>
                  {isActive && <span>{category.name}</span>}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </main>
  );
}
