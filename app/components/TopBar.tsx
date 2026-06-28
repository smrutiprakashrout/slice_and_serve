"use client";

import Image from "next/image";
import { MapPin, ChevronDown, ShoppingCart, User } from "lucide-react";

export default function TopBar() {
  return (
    <>
      {/* Logo / User / Cart row */}
      <div className="bg-[#fff1e3] w-full h-fit flex fixed top-0 z-50 justify-between items-center px-6 py-2">
        <div className="w-10 h-10 bg-yellow-900 rounded-xl flex items-center justify-center shadow-sm">
          <User className="w-5 h-5 text-white" />
        </div>

        <Image src="/images/logo.png" alt="logo" width={90} height={90} />

        <button className="w-10 h-10 bg-yellow-900 rounded-xl flex items-center justify-center relative shadow-sm">
          <ShoppingCart className="w-5 h-5 text-white" />
          <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white" />
        </button>
      </div>

      {/* Location row */}
      <header className="px-6 pb-4 pt-2 flex z-48 fixed w-full h-26 justify-between items-center bg-[#fff1e3]">
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
