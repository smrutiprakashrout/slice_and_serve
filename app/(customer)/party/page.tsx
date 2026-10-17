"use client";

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
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
  Plus,
  Check,
  X,
} from "lucide-react";
import {
  buildPartyListMessage,
  buildSingleDishMessage,
  buildWhatsAppUrl,
} from "@/lib/party-order-message";

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

const PARTY_LIST_STORAGE_KEY = "party-list-v1";
const EMPTY_PARTY_LIST: string[] = [];
const PARTY_MENU_IDS = new Set(PARTY_MENU.map((item) => item.id));
const partyListListeners = new Set<() => void>();
let partyListSnapshot: string[] = EMPTY_PARTY_LIST;
let partyListStorageRead = false;

function getPartyListSnapshot() {
  if (!partyListStorageRead && typeof window !== "undefined") {
    partyListStorageRead = true;
    try {
      const savedValue = window.sessionStorage.getItem(PARTY_LIST_STORAGE_KEY);
      const savedIds: unknown = savedValue ? JSON.parse(savedValue) : [];
      if (Array.isArray(savedIds)) {
        partyListSnapshot = Array.from(
          new Set(savedIds.filter((id): id is string => typeof id === "string" && PARTY_MENU_IDS.has(id))),
        );
      }
    } catch {
      partyListSnapshot = EMPTY_PARTY_LIST;
    }
  }

  return partyListSnapshot;
}

function subscribeToPartyList(listener: () => void) {
  partyListListeners.add(listener);
  return () => partyListListeners.delete(listener);
}

function getServerPartyListSnapshot() {
  return EMPTY_PARTY_LIST;
}

function updatePartyList(nextIds: string[]) {
  partyListSnapshot = Array.from(
    new Set(nextIds.filter((id) => PARTY_MENU_IDS.has(id))),
  );
  try {
    window.sessionStorage.setItem(
      PARTY_LIST_STORAGE_KEY,
      JSON.stringify(partyListSnapshot),
    );
  } catch {
    // Keep the list usable in memory when sessionStorage is unavailable.
  }
  partyListListeners.forEach((listener) => listener());
}

function stopTouchPropagation(event: React.TouchEvent<HTMLElement>) {
  event.stopPropagation();
}

export default function PartyMenuPage() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState<"left" | "right">("right");
  const [firstImageLoaded, setFirstImageLoaded] = useState(false);
  const [isPartyListOpen, setIsPartyListOpen] = useState(false);
  const partyList = useSyncExternalStore(
    subscribeToPartyList,
    getPartyListSnapshot,
    getServerPartyListSnapshot,
  );

  const imageStackRef = useRef<HTMLDivElement>(null);
  const infoRef = useRef<HTMLDivElement>(null);
  const swipeHintRef = useRef<HTMLDivElement>(null);
  const viewListButtonRef = useRef<HTMLButtonElement>(null);
  const addPartyItemButtonRef = useRef<HTMLButtonElement>(null);
  const partyListSheetRef = useRef<HTMLDivElement>(null);
  const focusAfterCloseRef = useRef<"view" | "add">("view");

  const touchStartX = useRef(0);
  const touchEndX = useRef(0);
  const touchStartY = useRef(0);
  const touchEndY = useRef(0);

  const activeItem = PARTY_MENU[currentIndex];
  const partyListItems = partyList
    .map((id) => PARTY_MENU.find((item) => item.id === id))
    .filter((item): item is PartyMenuItem => item !== undefined);
  const isActiveItemAdded = partyList.includes(activeItem.id);

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

  const togglePartyItem = () => {
    updatePartyList(
      isActiveItemAdded
        ? partyList.filter((id) => id !== activeItem.id)
        : [...partyList, activeItem.id],
    );
  };

  const removePartyItem = (id: string) => {
    const nextList = partyList.filter((itemId) => itemId !== id);
    updatePartyList(nextList);
    if (nextList.length === 0) {
      focusAfterCloseRef.current = "add";
      setIsPartyListOpen(false);
    }
  };

  const clearPartyList = () => {
    focusAfterCloseRef.current = "add";
    updatePartyList([]);
    setIsPartyListOpen(false);
  };

  useEffect(() => {
    if (!isPartyListOpen) return;

    const viewListButton = viewListButtonRef.current;
    const addPartyItemButton = addPartyItemButtonRef.current;
    const focusSheet = () => {
      const focusableElements = partyListSheetRef.current?.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])',
      );
      focusableElements?.[0]?.focus();
    };
    const animationFrame = window.requestAnimationFrame(focusSheet);

    const handleSheetKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        setIsPartyListOpen(false);
        return;
      }
      if (event.key !== "Tab") return;

      const focusableElements = partyListSheetRef.current?.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])',
      );
      if (!focusableElements?.length) return;
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];
      if (event.shiftKey && document.activeElement === firstElement) {
        event.preventDefault();
        lastElement.focus();
      } else if (!event.shiftKey && document.activeElement === lastElement) {
        event.preventDefault();
        firstElement.focus();
      }
    };

    document.addEventListener("keydown", handleSheetKeyDown);
    return () => {
      window.cancelAnimationFrame(animationFrame);
      document.removeEventListener("keydown", handleSheetKeyDown);
      window.requestAnimationFrame(() => {
        const returnFocusTarget = focusAfterCloseRef.current === "view"
          ? viewListButton
          : addPartyItemButton;
        returnFocusTarget?.focus();
      });
    };
  }, [isPartyListOpen]);

  const partyListNames = partyListItems.map((item) => item.name);

  return (
    <main
      className={`party-page min-h-dvh w-full bg-[#fff1e3] px-5 ${partyList.length > 0 ? "pb-[200px]" : "pb-32"} pt-[120px] font-sans text-yellow-900`}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&display=swap');
        .party-page .font-display { font-family: 'Playfair Display', Georgia, serif; }
        @media (prefers-reduced-motion: reduce) {
          .party-page .party-list-bar { transition: none; }
        }
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

          <button
            ref={addPartyItemButtonRef}
            type="button"
            aria-pressed={isActiveItemAdded}
            onClick={togglePartyItem}
            className={`mt-3 flex min-h-12 w-full items-center justify-center gap-2 rounded-2xl border px-4 text-base font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2 ${isActiveItemAdded ? "border-yellow-900 bg-[#fff1e3] text-yellow-900 hover:bg-[#f5e6d0]" : "border-yellow-900 bg-yellow-900 text-[#fff1e3] hover:bg-yellow-900/90"}`}
          >
            {isActiveItemAdded ? (
              <Check aria-hidden="true" className="h-5 w-5 text-[#fdc647]" />
            ) : (
              <Plus aria-hidden="true" className="h-5 w-5" />
            )}
            {isActiveItemAdded ? "Added to list" : "Add to party list"}
          </button>
          <a
            href={buildWhatsAppUrl(buildSingleDishMessage(activeItem.name))}
            target="_blank"
            rel="noopener noreferrer"
            className="self-center rounded px-2 py-1 text-sm text-yellow-900/75 underline decoration-[#f0d9b5] underline-offset-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647]"
          >
            Order just this dish on WhatsApp
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

      <div
        aria-hidden={partyList.length === 0}
        className={`party-list-bar fixed inset-x-4 bottom-[84px] z-40 mx-auto flex max-w-md items-center justify-between gap-3 rounded-2xl bg-yellow-900 px-4 py-2.5 text-[#fff1e3] shadow-xl transition-all duration-200 motion-reduce:transition-none ${partyList.length > 0 ? "translate-y-0 opacity-100" : "pointer-events-none invisible translate-y-2 opacity-0"}`}
        onTouchStart={stopTouchPropagation}
        onTouchMove={stopTouchPropagation}
        onTouchEnd={stopTouchPropagation}
      >
        <p className="min-w-0 truncate text-sm font-semibold">
          Party list · {partyList.length} {partyList.length === 1 ? "dish" : "dishes"}
        </p>
        <button
          ref={viewListButtonRef}
          type="button"
          onClick={() => {
            focusAfterCloseRef.current = "view";
            setIsPartyListOpen(true);
          }}
          className="flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-[#fdc647] px-4 text-sm font-bold text-yellow-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fff1e3] focus-visible:ring-offset-2 focus-visible:ring-offset-yellow-900"
        >
          View list
        </button>
      </div>

      {isPartyListOpen && (
        <div
          className="fixed inset-0 z-[60] bg-yellow-900/45"
          onClick={(event) => {
            if (event.target === event.currentTarget) setIsPartyListOpen(false);
          }}
          onTouchStart={stopTouchPropagation}
          onTouchMove={stopTouchPropagation}
          onTouchEnd={stopTouchPropagation}
        >
          <section
            ref={partyListSheetRef}
            role="dialog"
            aria-modal="true"
            aria-label="Your party list"
            tabIndex={-1}
            className="absolute inset-x-0 bottom-0 mx-auto flex max-h-[min(84dvh,760px)] w-full max-w-md flex-col rounded-t-3xl border border-[#f0d9b5] bg-[#fff1e3] px-5 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-5 text-yellow-900 shadow-2xl"
            onClick={(event) => event.stopPropagation()}
            onTouchStart={stopTouchPropagation}
            onTouchMove={stopTouchPropagation}
            onTouchEnd={stopTouchPropagation}
          >
            <header className="mb-4 flex shrink-0 items-center justify-between gap-3">
              <div>
                <h2 className="font-display text-2xl font-bold">Your party list</h2>
                <p className="mt-1 text-sm text-yellow-900/70">
                  {partyList.length} {partyList.length === 1 ? "dish" : "dishes"}
                </p>
              </div>
              <button
                type="button"
                aria-label="Close party list"
                onClick={() => setIsPartyListOpen(false)}
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-[#f0d9b5] bg-white text-yellow-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647]"
              >
                <X aria-hidden="true" className="h-5 w-5" />
              </button>
            </header>

            <ol className="min-h-0 flex-1 space-y-2 overflow-y-auto pb-3">
              {partyListItems.map((item, index) => (
                <li
                  key={item.id}
                  className="flex items-center gap-3 rounded-2xl border border-[#f0d9b5] bg-white p-3"
                >
                  <span className="w-6 shrink-0 text-sm font-bold text-yellow-900/70">
                    {index + 1}.
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold">{item.name}</p>
                    <p className="truncate text-xs text-yellow-900/70">{item.subtitle}</p>
                  </div>
                  <DietIcon type={item.type} />
                  <button
                    type="button"
                    aria-label={`Remove ${item.name}`}
                    onClick={() => removePartyItem(item.id)}
                    className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-yellow-900/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647]"
                  >
                    <X aria-hidden="true" className="h-5 w-5" />
                  </button>
                </li>
              ))}
            </ol>

            <footer className="flex shrink-0 flex-col gap-2 border-t border-[#f0d9b5] pt-3">
              <button
                type="button"
                onClick={clearPartyList}
                className="min-h-11 self-start rounded px-2 text-sm font-semibold text-yellow-900/75 underline underline-offset-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647]"
              >
                Clear all
              </button>
              <a
                href={buildWhatsAppUrl(buildPartyListMessage(partyListNames))}
                target="_blank"
                rel="noopener noreferrer"
                className="flex min-h-12 w-full items-center justify-center gap-2 rounded-2xl bg-yellow-900 px-4 text-base font-semibold text-[#fff1e3] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#fdc647] focus-visible:ring-offset-2"
              >
                <MessageCircle aria-hidden="true" className="h-5 w-5" />
                Send on WhatsApp
              </a>
              <p className="text-center text-xs text-yellow-900/70">
                We&apos;ll confirm quantity and price on WhatsApp.
              </p>
            </footer>
          </section>
        </div>
      )}
    </main>
  );
}
