import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { Pricing } from "@/components/Pricing";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Mac Cleaner Pro Pricing — $39 Pay-Once, No Subscription",
  description:
    "Mac Cleaner Pro costs $39 once for Pro (1 Mac) or $69 for Family (5 Macs). No subscription, no renewal. 14-day free trial and 30-day money-back guarantee. Cheaper than CleanMyMac subscription.",
  alternates: { canonical: `https://${brand.domain}/pricing/` },
};

export default function PricingPage() {
  return (
    <>
      <Nav />
      <main className="pt-24 md:pt-32" style={{ paddingBottom: 40 }}>
        <Pricing />
      </main>
      <Footer />
    </>
  );
}
