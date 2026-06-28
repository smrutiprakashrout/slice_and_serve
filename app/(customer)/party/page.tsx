"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import {
  ChevronLeft,
  ChevronRight,
  Star,
  ChevronsLeft,
  ChevronsRight,
  ChevronsLeftRight,
} from "lucide-react";

gsap.registerPlugin(useGSAP);

// --- Types & Data ---
interface PartyMenuItem {
  id: string;
  name: string;
  subtitle: string;
  rating: number;
  type: "veg" | "non-veg";
  image: string;
}

const PARTY_MENU: PartyMenuItem[] = [
  {
    id: "p1",
    name: "Finger Chicken",
    subtitle: "Crispy fried strips",
    rating: 4.5,
    type: "non-veg",
    image: "/images/party/Finger_Chicken.png",
  },
  {
    id: "p2",
    name: "Chicken Kebab",
    subtitle: "Juicy chicken kebab",
    rating: 4.7,
    type: "non-veg",
    image: "/images/party/Chicken_Kebab.png",
  },
  {
    id: "p3",
    name: "Chicken Pokoda",
    subtitle: "Crunchy spiced bites",
    rating: 4.6,
    type: "non-veg",
    image: "/images/party/Chicken_Pokoda.png",
  },
  {
    id: "p4",
    name: "Chili Chicken",
    subtitle: "Spicy & tangy",
    rating: 4.8,
    type: "non-veg",
    image: "/images/party/Chili_Chicken.png",
  },
  {
    id: "p5",
    name: "Chicken 65",
    subtitle: "Deep-fried classic",
    rating: 4.9,
    type: "non-veg",
    image: "/images/party/Chicken_65.png",
  },
  {
    id: "p6",
    name: "Drums of Heaven",
    subtitle: "Lollipop style",
    rating: 4.8,
    type: "non-veg",
    image: "/images/party/Drums_of_Heaven.png",
  },
  {
    id: "p7",
    name: "Chicken Popcorn",
    subtitle: "Bite-sized goodness",
    rating: 4.5,
    type: "non-veg",
    image: "/images/party/Chicken_Popcorn.png",
  },
  {
    id: "p8",
    name: "Dragon Chicken",
    subtitle: "Sweet & spicy",
    rating: 4.7,
    type: "non-veg",
    image: "/images/party/Dragon_Chicken.png",
  },
  {
    id: "p9",
    name: "Chicken Majestic",
    subtitle: "Dry roasted",
    rating: 4.6,
    type: "non-veg",
    image: "/images/party/Chicken_Majestic.png",
  },
  {
    id: "p10",
    name: "Crispy Spicy Chicken",
    subtitle: "Extra hot",
    rating: 4.8,
    type: "non-veg",
    image: "/images/party/Crispy_Spicy_Chicken.png",
  },
];

// Helper component for Veg/Non-Veg
const DietIcon = ({ type }: { type: "veg" | "non-veg" }) => {
  const isVeg = type === "veg";
  return (
    <div
      className={`flex items-center justify-center w-5 h-5 border-2 rounded-md bg-white shrink-0 ${
        isVeg ? "border-green-600" : "border-red-600"
      }`}
    >
      <div
        className={`w-2.5 h-2.5 rounded-full ${
          isVeg ? "bg-green-600" : "bg-red-600"
        }`}
      />
    </div>
  );
};

export default function PartyMenuPage() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState<"left" | "right">("right");

  // Refs for animations
  const slideRef = useRef<HTMLDivElement>(null);
  const imageRef = useRef<HTMLImageElement>(null);
  const swipeHintRef = useRef<HTMLDivElement>(null);

  // Touch tracking for mobile swipe
  const touchStartX = useRef(0);
  const touchEndX = useRef(0);

  const activeItem = PARTY_MENU[currentIndex];

  // Helper flags to disable loops
  const isFirstItem = currentIndex === 0;
  const isLastItem = currentIndex === PARTY_MENU.length - 1;

  // Navigation Logic (Bounded, No Loops)
  const handleNext = () => {
    if (!isLastItem) {
      setDirection("right");
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handlePrev = () => {
    if (!isFirstItem) {
      setDirection("left");
      setCurrentIndex((prev) => prev - 1);
    }
  };

  // Mobile Swipe Handlers
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.targetTouches[0].clientX;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    touchEndX.current = e.targetTouches[0].clientX;
  };

  const handleTouchEnd = () => {
    if (!touchStartX.current || !touchEndX.current) return;
    const distance = touchStartX.current - touchEndX.current;

    const isLeftSwipe = distance > 50; // Swiping finger left (moving to NEXT item)
    const isRightSwipe = distance < -50; // Swiping finger right (moving to PREV item)

    if (isLeftSwipe) handleNext();
    if (isRightSwipe) handlePrev();

    // Reset touch coordinates
    touchStartX.current = 0;
    touchEndX.current = 0;
  };

  // --- GSAP Animations ---
  useGSAP(() => {
    // 1. Infinite Floating Animation for the raw food PNG
    gsap.to(imageRef.current, {
      y: -25,
      rotation: 3,
      duration: 2.5,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    // 2. Animated Swipe Text Hint (Bottom Center)
    gsap.to(swipeHintRef.current, {
      x: 10,
      duration: 1.5,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    // 3. Animated Side Chevrons
    gsap.to(".swipe-hint-left", {
      x: -8,
      duration: 1,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    gsap.to(".swipe-hint-right", {
      x: 8,
      duration: 1,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
  }, []);

  // 4. Slide Transition Animation when swipe happens
  useGSAP(
    () => {
      const xOffset = direction === "right" ? 100 : -100;
      gsap.fromTo(
        slideRef.current,
        { x: xOffset, opacity: 0, scale: 0.95 },
        { x: 0, opacity: 1, scale: 1, duration: 0.5, ease: "power3.out" },
      );
    },
    { dependencies: [currentIndex], scope: slideRef },
  );

  return (
    <main
      className="bg-[#fff1e3] text-black font-sans h-dvh w-full overflow-hidden flex flex-col items-center justify-center relative touch-none select-none"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      <div className="max-w-md mx-auto w-full h-full flex flex-col relative z-10">
        {/* Top Header */}
        <header className="px-6 pt-2 pb-4 flex flex-col justify-center items-center w-full z-50 gap-2">
          {/* Shop Logo */}
          <img
            src="/logo2.svg"
            alt="Shop Logo"
            className="h-10 w-auto drop-shadow-sm"
          />
          <span className="text-sm font-bold tracking-widest uppercase text-black/80">
            Party Order
          </span>
        </header>

        {/* Dynamic Slide Content */}
        <div
          ref={slideRef}
          className="flex-1 flex flex-col w-full h-full justify-center pb-12 relative"
        >
          {/* Floating Image Area with Dynamic Swipe Hints */}
          <div className="flex-1 flex items-center justify-between px-2 relative w-full h-[40vh]">
            {/* LEFT Swipe Hint (Hidden if on first item) */}
            <div
              className={`flex flex-col items-center transition-opacity duration-300 ${isFirstItem ? "opacity-0" : "opacity-100"}`}
            >
              <ChevronsLeft className="swipe-hint-left w-8 h-8 text-black/30" />
            </div>

            {/* The Food PNG */}
            <img
              ref={imageRef}
              src={activeItem.image}
              alt={activeItem.name}
              className="w-64 h-64 sm:w-72 sm:h-72 object-contain drop-shadow-2xl z-10"
              style={{
                backgroundColor: activeItem.image
                  ? "transparent"
                  : "rgba(0,0,0,0.1)",
                borderRadius: activeItem.image ? "0" : "50%",
              }}
            />

            {/* RIGHT Swipe Hint (Hidden if on last item) */}
            <div
              className={`flex flex-col items-center transition-opacity duration-300 ${isLastItem ? "opacity-0" : "opacity-100"}`}
            >
              <ChevronsRight className="swipe-hint-right w-8 h-8 text-black/30" />
            </div>
          </div>

          {/* Animated Swipe Text (Before Rating) */}
          <div
            ref={swipeHintRef}
            className="w-full flex justify-center items-center gap-2 mb-6 text-black/60 z-20"
          >
            <ChevronsLeftRight className="w-4 h-4" />
            <span className="text-xs font-bold uppercase tracking-widest">
              Swipe to view the next item
            </span>
          </div>

          {/* Bottom Info Section */}
          <div className="px-8 flex flex-col gap-2 relative z-20">
            {/* Rating & Veg/Non-Veg Label */}
            <div className="flex items-center justify-between w-full mb-1">
              <div className="bg-black/10 backdrop-blur-md px-3 py-1 rounded-full flex items-center gap-1 border border-black/10">
                <Star className="w-4 h-4 text-black fill-current" />
                <span className="text-sm font-bold text-black">
                  {activeItem.rating}
                </span>
              </div>
              <DietIcon type={activeItem.type} />
            </div>

            <h1 className="text-2xl font-black leading-tight text-black drop-shadow-sm">
              {activeItem.name}
            </h1>

            <p className="text-lg text-black/70 font-bold">
              {activeItem.subtitle}
            </p>

            <div className="mt-2 mb-8 w-full">
              <button className="bg-black text-white w-full font-black text-lg px-8 py-4 rounded-xl shadow-[0_4px_20px_rgba(0,0,0,0.15)] active:scale-95 transition-transform">
                Add to Party List
              </button>
            </div>
          </div>
        </div>

        {/* Desktop Controls Bottom */}
        <div className="absolute bottom-6 left-0 w-full flex flex-col items-center justify-center z-50 pointer-events-none hidden md:flex">
          <div className="flex gap-4 pointer-events-auto">
            <button
              onClick={handlePrev}
              disabled={isFirstItem}
              className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 ${
                isFirstItem
                  ? "bg-black/5 text-black/20 cursor-not-allowed"
                  : "bg-black/5 backdrop-blur-md border border-black/10 hover:bg-black/10 text-black active:scale-95"
              }`}
            >
              <ChevronLeft className="w-6 h-6" />
            </button>
            <button
              onClick={handleNext}
              disabled={isLastItem}
              className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 ${
                isLastItem
                  ? "bg-black/5 text-black/20 cursor-not-allowed"
                  : "bg-black/5 backdrop-blur-md border border-black/10 hover:bg-black/10 text-black active:scale-95"
              }`}
            >
              <ChevronRight className="w-6 h-6" />
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
