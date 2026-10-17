"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

interface LatestRelease {
  versionName: string;
  buildNumber: number;
  publishedAt: string;
  releaseUrl: string;
  apk: {
    name: string;
    sizeBytes: number;
    downloadUrl: string;
  };
  sha256: string | null;
}

type ViewState = "gate" | "loading" | "ready" | "error";

export default function DownloadGate() {
  const router = useRouter();
  const [state, setState] = useState<ViewState>("gate");
  const [release, setRelease] = useState<LatestRelease | null>(null);
  const [copied, setCopied] = useState(false);

  async function loadRelease() {
    setState("loading");
    setRelease(null);
    setCopied(false);
    try {
      const response = await fetch("/api/admin-app/latest");
      if (!response.ok) throw new Error("Release lookup failed.");
      const result = (await response.json()) as LatestRelease;
      if (!result.apk?.downloadUrl || !result.releaseUrl) {
        throw new Error("Release data is incomplete.");
      }
      setRelease(result);
      setState("ready");
    } catch {
      setState("error");
    }
  }

  if (state === "gate") {
    return (
      <main className="min-h-dvh bg-[#fff1e3] px-6 flex items-center justify-center font-sans">
        <section className="w-full text-center">
          <h1 className="text-2xl font-bold text-yellow-950">Admin access only</h1>
          <p className="mt-3 text-yellow-950">
            This page is only for admin access. Are you admin?
          </p>
          <div className="mt-6 flex justify-center gap-3">
            <button
              type="button"
              onClick={loadRelease}
              className="rounded-lg bg-yellow-900 px-7 py-3 font-semibold text-white active:scale-95"
            >
              Yes
            </button>
            <button
              type="button"
              onClick={() => router.replace("/")}
              className="rounded-lg bg-yellow-900 px-7 py-3 font-semibold text-white active:scale-95"
            >
              No
            </button>
          </div>
        </section>
      </main>
    );
  }

  return (
    <main className="min-h-dvh bg-[#fff1e3] px-6 py-12 flex items-center justify-center font-sans">
      <section className="w-full rounded-2xl bg-white/70 p-6 shadow-sm">
        {state === "loading" ? (
          <p className="text-center text-yellow-950" role="status">Loading latest release…</p>
        ) : state === "error" ? (
          <div className="text-center">
            <h1 className="text-xl font-bold text-yellow-950">
              Couldn&apos;t load the latest release
            </h1>
            <a
              className="mt-4 inline-block text-yellow-900 underline"
              href="https://github.com/smrutiprakashrout/slice_and_serve/releases"
              target="_blank"
              rel="noreferrer"
            >
              View releases on GitHub
            </a>
            <button
              type="button"
              onClick={loadRelease}
              className="mt-5 block w-full rounded-lg bg-yellow-900 px-5 py-3 font-semibold text-white"
            >
              Retry
            </button>
          </div>
        ) : release ? (
          <div>
            <h1 className="text-2xl font-bold text-yellow-950">Slice &amp; Serve Admin</h1>
            <dl className="mt-5 space-y-3 text-sm text-yellow-950">
              <div className="flex justify-between gap-4">
                <dt>Version</dt>
                <dd>{release.versionName} (build {release.buildNumber})</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt>Published</dt>
                <dd>{new Date(release.publishedAt).toLocaleDateString()}</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt>APK size</dt>
                <dd>{(release.apk.sizeBytes / (1024 * 1024)).toFixed(2)} MB</dd>
              </div>
            </dl>
            <div className="mt-5">
              <p className="text-xs font-semibold text-yellow-950">SHA-256</p>
              <div className="mt-1 flex items-start gap-2">
                <code className="min-w-0 flex-1 break-all font-mono text-xs text-yellow-950">
                  {release.sha256 ?? "Unavailable"}
                </code>
                <button
                  type="button"
                  disabled={!release.sha256}
                  onClick={async () => {
                    if (!release.sha256) return;
                    try {
                      await navigator.clipboard.writeText(release.sha256);
                      setCopied(true);
                    } catch {
                      setCopied(false);
                    }
                  }}
                  className="shrink-0 text-xs font-semibold text-yellow-900 underline disabled:opacity-50"
                >
                  {copied ? "Copied" : "Copy"}
                </button>
              </div>
            </div>
            <a
              href={release.apk.downloadUrl}
              className="mt-6 block rounded-lg bg-yellow-900 px-5 py-3 text-center font-bold text-white active:scale-[0.99]"
            >
              Download APK
            </a>
            <a
              href={release.releaseUrl}
              target="_blank"
              rel="noreferrer"
              className="mt-4 block text-center text-sm font-semibold text-yellow-900 underline"
            >
              View release notes on GitHub
            </a>
            <p className="mt-5 text-xs leading-relaxed text-yellow-950">
              Android may ask you to allow installs from this source. If you already have the app,
              this installs as an update.
            </p>
          </div>
        ) : null}
      </section>
    </main>
  );
}
