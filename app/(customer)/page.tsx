"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  MapPin,
  ChevronDown,
  ShoppingCart,
  User,
  Star,
  Utensils, // NEW
  CreditCard, // NEW
  PartyPopper, // NEW
  Info, // NEW
  ClipboardList,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

// --- Types & Data ---
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
  image: string; // NEW: Image URL/Path
  available: boolean; // NEW: Availability toggle
}

const CATEGORIES: Category[] = [
  { id: "1", name: "All Dishes", slug: "all", icon: "🥡" },
  { id: "2", name: "Sandwitch", slug: "sandwitch", icon: "🥪" },
  { id: "3", name: "Burger", slug: "burger", icon: "🍔" },
  { id: "4", name: "Staters", slug: "staters", icon: "🍟" },
  { id: "5", name: "Drinks", slug: "drinks", icon: "🥤" },
];

const MOCK_MENU: MenuItem[] = [
  // --- BURGERS ---
  {
    id: "b1",
    name: "Chicken Burger",
    subtitle: "Classic chicken patty",
    price: 70,
    rating: 4.5,
    categorySlug: "burger",
    type: "non-veg",
    featured: true,
    image: "/images/burger.jpg",
    available: true,
  },

  // --- SANDWICHES ---
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
    available: false, // Set to false to demonstrate out-of-stock UI
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

  // --- STARTERS ---
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
  // --- DRINKS ---
  {
    id: "d1",
    name: "Blue Angel",
    subtitle: "Refreshing mocktail",
    price: 49,
    rating: 4.6,
    categorySlug: "drinks",
    type: "veg",
    featured: true,
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
    available: false, // Set to false to demonstrate out-of-stock UI
  },
];

export default function MobileMenu() {
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const listRef = useRef<HTMLDivElement>(null);

  const filteredMenu = MOCK_MENU.filter((item) => {
    if (activeCategory === "all") return true;
    return item.categorySlug === activeCategory;
  });

  const featuredMenu = MOCK_MENU.filter((item) => item.featured === true);

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
    { dependencies: [], scope: listRef },
  );

  const allCategory = CATEGORIES.find((c) => c.slug === "all");
  const otherCategories = CATEGORIES.filter((c) => c.slug !== "all");
  const isAllActive = activeCategory === "all";

  // Helper component for the Veg/Non-Veg icon
  const DietIcon = ({ type }: { type: "veg" | "non-veg" }) => {
    const isVeg = type === "veg";
    return (
      <div
        className={`flex items-center justify-center w-4 h-4 border-[1.5px] rounded-sm bg-white shrink-0 ${
          isVeg ? "border-green-600" : "border-red-600"
        }`}
      >
        <div
          className={`w-[6px] h-[6px] rounded-full ${
            isVeg ? "bg-green-600" : "bg-red-600"
          }`}
        />
      </div>
    );
  };

  return (
    <main className="bg-[#ffffff] font-sans h-dvh flex flex-col">
      <div className="max-w-md mx-auto w-full bg-[#fff1e3] h-full flex flex-col relative shadow-2xl">
        <div className="flex-1 overflow-y-auto pb-24">
          {/* Top Bar */}
          <header className="px-6 pt-4 pb-4 flex justify-between items-center">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-yellow-800 rounded-sm flex items-center justify-center shadow-sm">
                <User className="w-5 h-5 text-white" />
              </div>
              <div className="flex flex-col">
                <span className="text-xs text-gray-500 font-medium">
                  Location
                </span>
                <div className="flex items-center gap-1 cursor-pointer">
                  <MapPin className="w-4 h-4 text-black" />
                  <span className="text-sm font-bold text-black">
                    Saheswari Club, Salipur
                  </span>
                  <ChevronDown className="w-4 h-4 text-gray-500" />
                </div>
              </div>
            </div>
            <button className="w-10 h-10 bg-white rounded-md flex items-center justify-center relative shadow-sm">
              <ShoppingCart className="w-6 h-6 text-gray-400" />
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white" />
            </button>
          </header>

          {/* Popular Dishes */}
          <div ref={listRef}>
            <div className="px-6 mb-4">
              <h2 className="text-lg font-bold text-black">Popular Dishes</h2>
            </div>
            <div className="flex flex-row flex-nowrap gap-4 overflow-x-auto px-6 pb-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none]">
              {featuredMenu
                // Sort by Rating (Highest to Lowest).
                .sort((a, b) => b.rating - a.rating)
                .map((item, index) => {
                  const isDark = index % 2 === 0;
                  return (
                    <div
                      key={item.id}
                      className={`food-card relative rounded-xl p-6 h-32 w-62 shrink-0 overflow-hidden shadow-sm ${
                        isDark ? "bg-yellow-500" : "bg-yellow-900"
                      } text-white ${!item.available ? "opacity-75" : ""}`}
                    >
                      <div className="relative z-10 flex flex-col justify-center h-full pointer-events-none">
                        <div className="flex items-center gap-2 mb-1">
                          <DietIcon type={item.type} />
                          <h3 className="text-xl font-black truncate">
                            {item.name}
                          </h3>
                        </div>

                        <div className="flex items-center gap-4 mt-1">
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

                      {/* Featured Item Image */}
                      <div className="pointer-events-none absolute -right-8 top-1/2 -translate-y-1/2 w-40 h-40 rounded-full bg-white/10 flex items-center justify-center overflow-hidden">
                        {item.image ? (
                          <img
                            src={item.image}
                            alt={item.name}
                            className={`w-full h-full object-cover ${!item.available ? "grayscale" : ""}`}
                          />
                        ) : (
                          <span className="text-xs font-bold opacity-50 text-black">
                            IMAGE
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
            </div>
          </div>

          {/* Menu Title and "All" Button */}
          <div className="flex items-center justify-between px-6 mb-4 mt-2">
            <p className="font-bold text-xl text-black">Menu</p>
            {allCategory && (
              <button
                type="button"
                onClick={() => setActiveCategory(allCategory.slug)}
                className={`
                  flex items-center justify-center gap-2
                  rounded-xl font-bold text-sm h-10 px-4
                  transition-all duration-300 shadow-sm outline-none
                  ${
                    isAllActive
                      ? "bg-yellow-900 text-white border-2 border-yellow-900"
                      : "bg-white text-black border border-gray-200"
                  }
                `}
                style={{ WebkitTapHighlightColor: "transparent" }}
              >
                <span className="text-base leading-none flex items-center justify-center">
                  {allCategory.icon}
                </span>
                {/* Dynamically displaying total MOCK_MENU length */}
                <span>
                  {allCategory.name} ({MOCK_MENU.length})
                </span>
              </button>
            )}
          </div>

          {/* Categorized Menu Grid */}
          <div className="px-6 pb-36">
            <div className="grid grid-cols-2 gap-4">
              {filteredMenu.map((item) => (
                <div
                  key={`menu-${item.id}`}
                  className="bg-white rounded-2xl overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-gray-100 flex flex-col h-full relative"
                >
                  {/* Image Header Area */}
                  <div className="h-32 bg-gray-100 relative w-full flex items-center justify-center shrink-0 overflow-hidden">
                    {item.image ? (
                      <img
                        src={item.image}
                        alt={item.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <span className="text-xs text-gray-400 font-bold tracking-widest uppercase">
                        Image
                      </span>
                    )}

                    {/* Floating Veg/Non-Veg Icon */}
                    <div className="absolute top-2 right-2 bg-white rounded p-[3px] shadow-sm z-10">
                      <DietIcon type={item.type} />
                    </div>

                    {/* Out of stock visual overlay on image */}
                    {!item.available && (
                      <div className="absolute inset-0 bg-white/50 backdrop-blur-[2px] flex items-center justify-center z-20">
                        <span className="bg-black text-white text-[10px] font-bold px-2 py-1 uppercase tracking-wider rounded-md shadow-sm">
                          Out of Stock
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Content Area */}
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

                    {/* Price & Buy Button Row */}
                    <div className="flex items-center justify-between mt-3 pt-1">
                      <span className="font-extrabold text-sm text-gray-900">
                        ₹{item.price}
                      </span>
                      <button
                        disabled={!item.available}
                        className={`font-bold text-xs px-4 py-1.5 rounded-lg transition-colors shadow-sm active:scale-95 ${
                          item.available
                            ? "bg-[#fdc647] text-black hover:bg-yellow-400"
                            : "bg-gray-200 text-gray-500 cursor-not-allowed shadow-none"
                        }`}
                      >
                        {item.available ? "Buy" : "Sold Out"}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Empty State Fallback */}
            {filteredMenu.length === 0 && (
              <div className="text-center py-10">
                <p className="text-gray-500 font-medium text-sm">
                  No items found in this category.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Remaining Categories Grid (Fixed above Bottom Nav) */}
        <div className="flex flex-wrap fixed bottom-16 w-full max-w-md justify-center gap-3 px-4 py-2 z-40 bg-gradient-to-t from-[#fff1e3] via-[#fff1e3] to-transparent pt-8">
          {otherCategories.map((category) => {
            const isActive = activeCategory === category.slug;
            return (
              <button
                key={category.id}
                type="button"
                onClick={() => setActiveCategory(category.slug)}
                className={`
                  flex items-center justify-center gap-2
                  rounded-xl font-bold text-sm h-12
                  transition-all duration-300 shadow-sm outline-none
                  ${
                    isActive
                      ? "bg-yellow-900 text-white border-2 border-yellow-900 px-5"
                      : "bg-white text-black border border-gray-200 w-12"
                  }
                `}
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

        {/* BOTTOM NAVIGATION BAR */}
        <div className="absolute bottom-0 left-0 w-full bg-white rounded-t-3xl shadow-[0_-10px_40px_rgba(0,0,0,0.05)] border-t border-gray-100 z-50">
          <div className="flex justify-between items-center px-8 py-3">
            <button className="flex flex-col items-center gap-1">
              <Utensils className="w-6 h-6 text-yellow-500" />
              <span className="text-[10px] font-bold text-yellow-500">
                Menu
              </span>
            </button>
            <button className="flex flex-col items-center gap-1">
              <CreditCard className="w-6 h-6 text-gray-400" />
              <span className="text-[10px] font-bold text-gray-400">
                Loyalty Card
              </span>
            </button>
            <button className="flex flex-col items-center gap-1 relative">
              <PartyPopper className="w-6 h-6 text-gray-400" />
              <span className="text-[10px] font-bold text-gray-400">
                Party Menu
              </span>
            </button>
            <button className="flex flex-col items-center gap-1 relative">
              {/* Notification Dot */}
              <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full border-2 border-white"></div>
              <ClipboardList className="w-6 h-6 text-gray-400" />
              <span className="text-[10px] font-bold text-gray-400">
                Orders
              </span>
            </button>
            <button className="flex flex-col items-center gap-1">
              <Info className="w-6 h-6 text-gray-400" />
              <span className="text-[10px] font-bold text-gray-400">About</span>
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
