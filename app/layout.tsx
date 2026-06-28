import type { Metadata } from "next";
import "./globals.css";
import BottomNav from "./components/BottomNav";
import TopBar from "./components/TopBar";

export const metadata: Metadata = {
  title: "Slice and Serve",
  description: "A premium, curated dining experience.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased bg-black text-white">
        <div className="max-w-md mx-auto w-full h-dvh relative">
          <TopBar />
          {children}
          <BottomNav />
        </div>
      </body>
    </html>
  );
}
