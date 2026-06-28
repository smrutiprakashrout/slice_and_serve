// app/layout.tsx  ← bare shell, no nav bars here
import type { Metadata } from "next";
import "./globals.css";

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
      <body className="antialiased bg-black text-white">{children}</body>
    </html>
  );
}
