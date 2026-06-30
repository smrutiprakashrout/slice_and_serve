// app/(customer)/layout.tsx  ← TopBar + BottomNav live HERE
import TopBar from "../components/TopBar";
import BottomNav from "../components/BottomNav";

export default function CustomerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="max-w-md mx-auto w-full h-dvh relative flex flex-col bg-[#fff1e3]">
      <TopBar />
      <div data-scroll-container className="flex-1 overflow-y-auto">
        {children}
      </div>
      <BottomNav />
    </div>
  );
}
