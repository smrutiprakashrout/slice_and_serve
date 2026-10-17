"use client";

import { useState, useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import Image from "next/image";
import {
  ChevronLeft,
  ChevronRight,
  Star,
  ChevronsLeft,
  ChevronsRight,
  ChevronsLeftRight,
  MessageCircle,
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
  const [firstImageLoaded, setFirstImageLoaded] = useState(false);

  const imageStackRef = useRef<HTMLDivElement>(null);
  const infoRef = useRef<HTMLDivElement>(null);
  const swipeHintRef = useRef<HTMLDivElement>(null);

  const touchStartX = useRef(0);
  const touchEndX = useRef(0);
  const touchStartY = useRef(0);
  const touchEndY = useRef(0);

  const activeItem = PARTY_MENU[currentIndex];

  const isFirstItem = currentIndex === 0;
  const isLastItem = currentIndex === PARTY_MENU.length - 1;

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

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.targetTouches[0].clientX;
    touchStartY.current = e.targetTouches[0].clientY;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    touchEndX.current = e.targetTouches[0].clientX;
    touchEndY.current = e.targetTouches[0].clientY;
  };

  const handleTouchEnd = () => {
    if (!touchStartX.current || !touchEndX.current) {
      touchStartX.current = 0;
      touchEndX.current = 0;
      touchStartY.current = 0;
      touchEndY.current = 0;
      return;
    }
    const distance = touchStartX.current - touchEndX.current;
    const verticalDistance = touchStartY.current - touchEndY.current;

    const isLeftSwipe = distance > 50; // Swiping finger left (moving to NEXT item)
    const isRightSwipe = distance < -50; // Swiping finger right (moving to PREV item)

    if (Math.abs(verticalDistance) <= Math.abs(distance)) {
      if (isLeftSwipe) handleNext();
      if (isRightSwipe) handlePrev();
    }

    touchStartX.current = 0;
    touchEndX.current = 0;
    touchStartY.current = 0;
    touchEndY.current = 0;
  };

  useGSAP(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    gsap.to(imageStackRef.current, {
      y: -12,
      rotation: 1.5,
      duration: 2.5,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
    gsap.to(swipeHintRef.current, {
      x: 6,
      duration: 1.5,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    gsap.to(".swipe-hint-left", {
      x: -5,
      duration: 1,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    gsap.to(".swipe-hint-right", {
      x: 5,
      duration: 1,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });
  }, []);

  useGSAP(
    () => {
      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
      const xOffset = direction === "right" ? 12 : -12;
      gsap.fromTo(
        infoRef.current,
        { x: xOffset, opacity: 0 },
        { x: 0, opacity: 1, duration: 0.22, ease: "power2.out" },
      );
    },
    { dependencies: [currentIndex], scope: infoRef },
  );

  const handleDotClick = (index: number) => {
    if (index === currentIndex) return;
    setDirection(index > currentIndex ? "right" : "left");
    setCurrentIndex(index);
  };

  const whatsappMessage = `Hi Slice & Serve, I'd like to place a party order for ${activeItem.name}.`;
  const whatsappUrl = `https://wa.me/919337867207?text=${encodeURIComponent(whatsappMessage)}`;

  return (
    <main
      className="party-page min-h-dvh w-full bg-[#fff1e3] px-5 pb-32 pt-[120px] font-sans text-yellow-900"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&display=swap');
        .party-page .font-display { font-family: 'Playfair Display', Georgia, serif; }
      `}</style>
      <div className="mx-auto flex w-full max-w-md flex-col gap-5">
        <header className="text-center">
          <span className="text-xs font-bold tracking-[0.2em] text-yellow-900/80 uppercase">
            Party Order Menu
          </span>
        </header>

        <section aria-label="Party menu item" className="flex flex-col items-center">
          <div className="flex w-full items-center justify-between gap-2">
            <div className={`flex h-11 w-11 items-center justify-center transition-opacity duration-300 ${isFirstItem ? "pointer-events-none opacity-0" : "opacity-100"}`}>
              <ChevronsLeft aria-hidden="true" className="swipe-hint-left h-8 w-8 text-yellow-900/45" />
            </div>
            <div className="relative flex h-64 w-64 shrink-0 items-center justify-center sm:h-72 sm:w-72">
              <div
                aria-hidden="true"
                className={`absolute h-[72%] w-[72%] rounded-full bg-[#f5e6d0] transition-opacity duration-300 ${firstImageLoaded ? "opacity-0" : "opacity-100"}`}
              />
              <div ref={imageStackRef} className="absolute inset-0">
                {PARTY_MENU.map((item, index) => {
                  const isActive = index === currentIndex;
                  return (
                    <div
                      key={item.id}
                      aria-hidden={!isActive}
                      className={`absolute inset-0 flex items-center justify-center transition-opacity duration-[250ms] motion-reduce:transition-none ${isActive ? "z-10 opacity-100" : "pointer-events-none opacity-0"}`}
                    >
                      <Image
                        src={item.image}
                        width={288}
                        height={288}
                        sizes="(max-width: 640px) 256px, 288px"
                        priority={index === 0 || Math.abs(index - currentIndex) <= 1}
                        loading="eager"
                        onLoad={index === 0 ? () => setFirstImageLoaded(true) : undefined}
                        alt={item.name}
                        className="h-full w-full object-contain drop-shadow-xl"
                      />
                    </div>
                  );
                })}
              </div>
            </div>
            <div className={`flex h-11 w-11 items-center justify-center transition-opacity duration-300 ${isLastItem ? "pointer-events-none opacity-0" : "opacity-100"}`}>
              <ChevronsRight aria-hidden="true" className="swipe-hint-right h-8 w-8 text-yellow-900/45" />
            </div>
          </div>

          <div className="mt-1 flex flex-col items-center gap-3">
            <div aria-live="polite" className="text-xs font-semibold tabular-nums text-yellow-900/75">
              {currentIndex + 1} / {PARTY_MENU.length}
            </div>
            <div className="flex min-h-11 w-full items-center justify-center gap-0" aria-label="Choose a party menu item">
              {PARTY_MENU.map((item, index) => (
                <button
                  key={item.id}
                  type="button"
                  aria-label={`Show ${item.name}`}
                  aria-current={index === currentIndex ? "step" : undefined}
                  onClick={() => handleDotClick(index)}
                  className="flex h-11 w-6 shrink-0 items-center justify-center rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
                >
                  <span className={`h-2 rounded-full transition-all duration-200 ${index === currentIndex ? "w-6 bg-[#fdc647]" : "w-2 bg-[#f0d9b5]"}`} />
                </button>
              ))}
            </div>
          </div>

          <div
            ref={swipeHintRef}
            className="mt-2 flex items-center justify-center gap-2 text-sm text-yellow-900/70"
          >
            <ChevronsLeftRight aria-hidden="true" className="h-4 w-4" />
            <span>Swipe to view the next item</span>
          </div>
        </section>

        <section ref={infoRef} className="flex flex-col gap-2 rounded-3xl border border-[#f0d9b5] bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5 rounded-full border border-[#f0d9b5] bg-[#fff1e3] px-3 py-1.5">
              <Star aria-hidden="true" className="h-4 w-4 fill-[#fdc647] text-[#fdc647]" />
              <span className="text-sm font-bold text-yellow-900">{activeItem.rating}</span>
            </div>
            <DietIcon type={activeItem.type} />
          </div>

          <h1 className="font-display text-2xl font-bold leading-tight text-yellow-900">
            {activeItem.name}
          </h1>
          <p className="text-base font-medium text-yellow-900/70">
            {activeItem.subtitle}
          </p>

          <a
            href={whatsappUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-3 flex min-h-12 w-full items-center justify-center gap-2 rounded-2xl bg-yellow-900 px-4 text-base font-semibold text-[#fff1e3] transition-colors hover:bg-yellow-900/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
          >
            <MessageCircle aria-hidden="true" className="h-5 w-5" />
            Order on WhatsApp
          </a>
          <p className="text-center text-xs text-yellow-900/70">
            Party orders are taken on WhatsApp. Open daily 3:30 PM – 10:00 PM.
          </p>
        </section>

        <div className="hidden justify-center gap-4 md:flex">
          <div className="flex gap-4">
            <button
              type="button"
              onClick={handlePrev}
              disabled={isFirstItem}
              aria-label="Previous party menu item"
              className={`flex h-12 w-12 items-center justify-center rounded-full border border-[#f0d9b5] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2 ${
                isFirstItem
                  ? "cursor-not-allowed bg-[#f5e6d0] text-yellow-900/35"
                  : "bg-white text-yellow-900 hover:bg-[#f5e6d0]"
              }`}
            >
              <ChevronLeft aria-hidden="true" className="h-6 w-6" />
            </button>
            <button
              type="button"
              onClick={handleNext}
              disabled={isLastItem}
              aria-label="Next party menu item"
              className={`flex h-12 w-12 items-center justify-center rounded-full border border-[#f0d9b5] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2 ${
                isLastItem
                  ? "cursor-not-allowed bg-[#f5e6d0] text-yellow-900/35"
                  : "bg-white text-yellow-900 hover:bg-[#f5e6d0]"
              }`}
            >
              <ChevronRight aria-hidden="true" className="h-6 w-6" />
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
