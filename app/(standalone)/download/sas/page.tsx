import type { Metadata } from "next";
import DownloadGate from "./DownloadGate";

export const metadata: Metadata = {
  title: "Admin access only",
  robots: { index: false, follow: false },
};

export default function SasDownloadPage() {
  return <DownloadGate />;
}
