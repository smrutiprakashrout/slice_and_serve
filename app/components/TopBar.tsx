"use client";

import Image from "next/image";
import { MapPin, ChevronDown, ShoppingCart, User } from "lucide-react";
import { useRouter } from "next/navigation";
import { useCartStore } from "@/lib/cart-store";

export default function TopBar() {
  const router = useRouter();

  // Subscribe to items array — re-renders instantly on every cart change
  const items = useCartStore((s) => s.items);
  const totalItems = items.reduce((sum, i) => sum + i.qty, 0);

  return (
    <>
      {/* Logo / User / Cart row */}

      <div className="fixed top-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-[#fff1e3] z-50 flex justify-between items-center px-6 py-2">
        <button
          onClick={() => router.push("/profile")}
          className="w-10 h-10 bg-yellow-900 rounded-xl flex items-center justify-center shadow-sm active:scale-95 transition-transform"
        >
          <User className="w-5 h-5 text-white" />
        </button>

        <Image src="/images/logo.png" alt="logo" width={90} height={90} />

        {/* Cart button — live badge, navigates to /cart */}
        <button
          onClick={() => router.push("/cart")}
          className="relative w-10 h-10 bg-yellow-900 rounded-xl flex items-center justify-center shadow-sm active:scale-95 transition-transform"
        >
          <ShoppingCart className="w-5 h-5 text-white" />
          {totalItems > 0 ? (
            // Live count badge — replaces the static red dot
            <span className="absolute -top-1.5 -right-1.5 min-w-[18px] h-[18px] bg-red-500 text-white text-[9px] font-black rounded-full flex items-center justify-center px-1 border-2 border-[#fff1e3]">
              {totalItems}
            </span>
          ) : (
            // Static dot when cart is empty
            <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white" />
          )}
        </button>
      </div>

      {/* Location row */}
      <header className="px-6 pb-4 pt-2 flex z-48 fixed w-full max-w-md h-26 justify-between items-center bg-[#fff1e3]">
        <div className="flex items-center w-full">
          <div className="flex flex-col justify-center items-center w-full">
            <div className="flex bg-yellow-900 fixed top-16 z-50 px-4 py-1 rounded-md items-center gap-1 cursor-pointer">
              <MapPin className="w-4 h-4 text-white" />
              <span className="text-sm font-bold text-white">
                Saheswari Club, Salipur
              </span>
              <ChevronDown className="w-4 h-4 text-white" />
            </div>
          </div>
        </div>
      </header>
    </>
  );
}
