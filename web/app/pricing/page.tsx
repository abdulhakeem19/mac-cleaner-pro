import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { Pricing } from "@/components/Pricing";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Pricing",
  description:
    "Mac Cleaner Pro is pay-once — $39 for Pro, $69 for Family. 14-day free trial, 30-day refund guarantee. No subscription, ever.",
  alternates: { canonical: `https://${brand.domain}/pricing/` },
};

export default function PricingPage() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 100, paddingBottom: 40 }}>
        <Pricing />
      </main>
      <Footer />
    </>
  );
}
