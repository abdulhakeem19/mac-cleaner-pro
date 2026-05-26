import type { Metadata } from "next";
import { Suspense } from "react";
import { brand } from "@/content/site";
import { CheckoutForm } from "@/components/CheckoutForm";

export const metadata: Metadata = {
  title: "Checkout — Mac Cleaner Pro",
  description: "Complete your Mac Cleaner Pro purchase securely with Razorpay or Paddle.",
  alternates: { canonical: `https://${brand.domain}/checkout/` },
  robots: "noindex", // Don't index checkout page
};

export default function CheckoutPage() {
  return (
    <main className="min-h-screen flex items-center justify-center" style={{ padding: "40px 20px", background: "var(--bg)" }}>
      <Suspense fallback={<div style={{ fontSize: 14, color: "var(--text-muted)" }}>Loading checkout...</div>}>
        <CheckoutForm />
      </Suspense>
    </main>
  );
}
