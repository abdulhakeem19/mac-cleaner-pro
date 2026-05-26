import type { Metadata } from "next";
import { Suspense } from "react";
import { brand } from "@/content/site";
import { SuccessView } from "@/components/SuccessView";

export const metadata: Metadata = {
  title: "Payment Successful — Mac Cleaner Pro",
  description: "Your Mac Cleaner Pro license key has been sent to your email.",
  alternates: { canonical: `https://${brand.domain}/success/` },
  robots: "noindex", // Don't index success page
};

export default function SuccessPage() {
  return (
    <main className="min-h-screen flex items-center justify-center" style={{ padding: "40px 20px", background: "var(--bg)" }}>
      <Suspense fallback={<div style={{ fontSize: 14, color: "var(--text-muted)" }}>Loading...</div>}>
        <SuccessView />
      </Suspense>
    </main>
  );
}
