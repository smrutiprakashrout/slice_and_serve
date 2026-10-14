"use client";

import { useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { animate, createScope, createTimeline, type Scope } from "animejs";
import Image from "next/image";
import { ShieldCheck } from "lucide-react";
// Client-side signIn — must come from next-auth/react (not @/auth) because
// this is a "use client" component.
import { signIn } from "next-auth/react";

// ─── Google "G" logo — inline SVG, brand-accurate colours ────────────────────
function GoogleIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 48 48" className="shrink-0">
      <path
        fill="#FFC107"
        d="M43.6 20.5H42V20H24v8h11.3c-1.6 4.6-6 8-11.3 8-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34.6 6.1 29.6 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.6-.4-3.5z"
      />
      <path
        fill="#FF3D00"
        d="M6.3 14.7l6.6 4.8C14.6 16 19 13 24 13c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34.6 6.1 29.6 4 24 4 16.3 4 9.6 8.3 6.3 14.7z"
      />
      <path
        fill="#4CAF50"
        d="M24 44c5.5 0 10.5-2.1 14.3-5.6l-6.6-5.6C29.6 34.7 26.9 36 24 36c-5.3 0-9.7-3.4-11.3-8.1l-6.5 5C9.5 39.6 16.2 44 24 44z"
      />
      <path
        fill="#1976D2"
        d="M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.2 4.2-4.1 5.7l6.6 5.6C40.8 36.6 44 30.9 44 24c0-1.3-.1-2.6-.4-3.5z"
      />
    </svg>
  );
}

export default function LoginPage() {
  const router = useRouter();
  const rootRef = useRef<HTMLDivElement>(null);
  const scope = useRef<Scope | null>(null);

  useEffect(() => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    scope.current = createScope({ root: rootRef as any }).add((self) => {
      // ── Entrance sequence ──
      createTimeline({ defaults: { ease: "outExpo" } })
        .add(".login-logo", {
          scale: [0.7, 1],
          opacity: [0, 1],
          duration: 700,
          ease: "outBack(1.6)",
        })
        .add(
          ".login-eyebrow",
          { y: [14, 0], opacity: [0, 1], duration: 450 },
          "-=250",
        )
        .add(
          ".login-title",
          { y: [22, 0], opacity: [0, 1], duration: 550 },
          "-=300",
        )
        .add(
          ".login-sub",
          { y: [16, 0], opacity: [0, 1], duration: 500 },
          "-=350",
        )
        .add(
          ".login-button",
          { y: [18, 0], opacity: [0, 1], duration: 500 },
          "-=300",
        )
        .add(".login-footer", { opacity: [0, 1], duration: 400 }, "-=200");

      // ── Ambient breathing glow — restrained, slow, continuous ──
      animate(".login-glow", {
        scale: [1, 1.15],
        opacity: [0.3, 0.55],
        duration: 2800,
        loop: true,
        alternate: true,
        ease: "inOutSine",
      });

      // Register a callable click-bounce method for the button
      self.add("bounceButton", () => {
        animate(".login-button", {
          scale: [1, 0.97, 1],
          duration: 200,
          ease: "outQuad",
        });
      });
    });

    return () => scope.current?.revert();
  }, []);

  const handleGoogleLogin = () => {
    scope.current?.methods.bounceButton();
    signIn("google", { callbackUrl: "/" });
  };

  return (
    <div
      ref={rootRef}
      className="min-h-dvh bg-yellow-400 flex flex-col items-center justify-between px-8 py-12 relative overflow-hidden"
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Inter:wght@400;500;600;700;800&display=swap');
        .font-display { font-family: 'Playfair Display', Georgia, serif; }
        .font-body    { font-family: 'Inter', system-ui, sans-serif; }
      `}</style>

      {/* Subtle dot texture */}
      <div
        className="absolute inset-0 opacity-[0.06] pointer-events-none"
        style={{
          backgroundImage:
            "radial-gradient(circle at 1px 1px, #3d1a00 1px, transparent 0)",
          backgroundSize: "26px 26px",
        }}
      />

      {/* Ambient corner glows */}
      <div className="absolute -top-24 -right-24 w-72 h-72 bg-[#3d1a00] rounded-full blur-[110px] opacity-[0.12] pointer-events-none" />
      <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-[#8B1A1A] rounded-full blur-[100px] opacity-[0.15] pointer-events-none" />

      {/* Spacer top */}
      <div />

      {/* ── Center content ──────────────────────────────────────── */}
      <div className="relative z-10 flex flex-col items-center text-center max-w-xs">
        {/* Logo with breathing glow ring */}
        <div className="login-logo relative mb-9 opacity-0">
          <div className="login-glow absolute inset-0 rounded-full bg-[#3d1a00] opacity-30 blur-2xl scale-100" />
          <div className="relative w-24 h-24 bg-[#fff1e3] rounded-[28px] flex items-center justify-center shadow-2xl border border-[#3d1a00]/10">
            <Image
              src="/images/logo.png"
              alt="Slice and Serve"
              width={64}
              height={64}
              className="object-contain"
            />
          </div>
        </div>

        {/* Eyebrow */}
        <p className="login-eyebrow opacity-0 text-[#3d1a00] text-[11px] font-bold tracking-[0.3em] uppercase mb-3">
          Login to Continue
        </p>

        {/* Headline */}
        <h1 className="login-title opacity-0 font-display text-[2.1rem] font-black text-[#3d1a00] leading-[1.15] mb-3">
          Good food starts
          <br />
          with one tap
        </h1>

        {/* Subtext */}
        <p className="login-sub opacity-0 font-body text-[#3d1a00]/70 text-sm leading-relaxed mb-10">
          Sign in to track orders, collect loyalty stamps, and pick up right
          where you left off.
        </p>

        {/* Google Sign-in button */}
        <button
          onClick={handleGoogleLogin}
          className="login-button opacity-0 w-full h-14 bg-[#fff1e3] hover:bg-white text-[#2a1800] font-bold text-sm rounded-2xl flex items-center justify-center gap-3 shadow-xl active:scale-[0.97] transition-transform duration-200"
        >
          <GoogleIcon />
          Continue with Google
        </button>

        {/* Security note */}
        <div className="login-footer opacity-0 flex items-center gap-1.5 mt-5">
          <ShieldCheck
            className="w-3.5 h-3.5 text-[#3d1a00]/50"
            strokeWidth={2}
          />
          <p className="text-[11px] text-[#3d1a00]/50 font-medium">
            We never post or share without your permission
          </p>
        </div>
      </div>

      {/* ── Footer legal ───────────────────────────────────────── */}
      <div className="login-footer opacity-0 relative z-10 text-center px-4">
        <p className="font-body text-[11px] text-[#3d1a00]/45 leading-relaxed">
          By continuing, you agree to Slice and Serve's
          <br />
          <span className="text-[#3d1a00]/70 font-semibold">
            Terms of Service
          </span>{" "}
          and{" "}
          <span className="text-[#3d1a00]/70 font-semibold">
            Privacy Policy
          </span>
        </p>
      </div>
    </div>
  );
}
