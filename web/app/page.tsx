import type { Metadata } from "next";
import { BuiltInPublicTimeline } from "@/components/BuiltInPublicTimeline";
import { FAQ } from "@/components/FAQ";
import { FeaturesGrid } from "@/components/FeaturesGrid";
import { Footer } from "@/components/Footer";
import { FooterCTA } from "@/components/FooterCTA";
import { Hero } from "@/components/Hero";
import { HonestyCard } from "@/components/HonestyCard";
import { HowItWorks } from "@/components/HowItWorks";
import { Nav } from "@/components/Nav";
import { NativeEdge } from "@/components/NativeEdge";
import { Pricing } from "@/components/Pricing";
import { SecurityCallout } from "@/components/SecurityCallout";
import { SmartScanDemo } from "@/components/SmartScanDemo";
import { SystemRequirements } from "@/components/SystemRequirements";
import { TechMarquee } from "@/components/TechMarquee";

export const metadata: Metadata = {
  title: "Mac Cleaner Pro — See & Clean System Data on macOS · No Subscription",
  description:
    "Finally understand what's hiding in System Data — and clean it. Mac Cleaner Pro is the honest, pay-once CleanMyMac alternative. Native Swift, zero telemetry, 14-day free trial.",
  alternates: {
    canonical: "https://maccleanerpro.com/",
  },
  openGraph: {
    title: "Mac Cleaner Pro — See & Clean System Data on macOS · No Subscription",
    description:
      "Finally understand what's hiding in System Data — and clean it. Mac Cleaner Pro is the honest, pay-once CleanMyMac alternative. Native Swift, zero telemetry, 14-day free trial.",
    url: "https://maccleanerpro.com/",
  },
};

export default function HomePage() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <TechMarquee />
        <HonestyCard />
        <div className="section-accent-blue">
          <SmartScanDemo />
        </div>
        <FeaturesGrid />
        <div className="section-accent-purple">
          <NativeEdge />
        </div>
        <HowItWorks />
        <div className="section-accent-green">
          <SecurityCallout />
        </div>
        <Pricing />
        <BuiltInPublicTimeline />
        <FAQ />
        <SystemRequirements />
        <FooterCTA />
      </main>
      <Footer />
    </>
  );
}
