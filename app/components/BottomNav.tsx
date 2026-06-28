"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Utensils,
  CreditCard,
  PartyPopper,
  ClipboardList,
  Info,
} from "lucide-react";

const NAV_ITEMS = [
  {
    id: "menu",
    label: "Menu",
    icon: Utensils,
    href: "/",
    hasNotification: false,
  },
  {
    id: "loyalty",
    label: "Loyalty",
    icon: CreditCard,
    href: "/loyalty",
    hasNotification: false,
  },
  {
    id: "party",
    label: "Party",
    icon: PartyPopper,
    href: "/party",
    hasNotification: false,
  },
  {
    id: "orders",
    label: "Orders",
    icon: ClipboardList,
    href: "/orders",
    hasNotification: true,
  },
  {
    id: "about",
    label: "About",
    icon: Info,
    href: "/about",
    hasNotification: false,
  },
];

export default function BottomNav() {
  const pathname = usePathname();

  return (
    <div className="fixed bottom-4 left-1/2 -translate-x-1/2 w-[90%] max-w-sm z-50">
      <div className="bg-yellow-900 rounded-lg shadow-xl flex justify-between items-center px-2 py-2">
        {NAV_ITEMS.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.id}
              href={item.href}
              className={`
                relative flex items-center justify-center gap-2 h-10 transition-all duration-300 outline-none
                ${isActive ? "bg-white text-[#1a1b26] px-4 rounded-lg" : "text-white w-10 bg-transparent"}
              `}
              style={{ WebkitTapHighlightColor: "transparent" }}
            >
              <Icon
                className={`w-[18px] h-[18px] ${isActive ? "text-[#1a1b26]" : "text-white"}`}
                strokeWidth={isActive ? 2.5 : 2}
              />

              {isActive && (
                <span className="text-xs font-bold whitespace-nowrap">
                  {item.label}
                </span>
              )}

              {/* Notification Dot */}
              {item.hasNotification && !isActive && (
                <div className="absolute top-[8px] right-[8px] w-2 h-2 bg-red-500 rounded-full border-[1.5px] border-[#1a1b26]"></div>
              )}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
