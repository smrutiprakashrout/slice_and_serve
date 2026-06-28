// app/(standalone)/layout.tsx  ← NO nav bars, pure full screen
export default function StandaloneLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <div className="max-w-md mx-auto w-full min-h-dvh">{children}</div>;
}
