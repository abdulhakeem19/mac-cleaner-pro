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
import { Support } from "@/components/Support";
import { SecurityCallout } from "@/components/SecurityCallout";
import { SmartScanDemo } from "@/components/SmartScanDemo";
import { SystemRequirements } from "@/components/SystemRequirements";
import { TechMarquee } from "@/components/TechMarquee";

export const metadata: Metadata = {
  title: "Mac Cleaner Pro — Free, Open Source Mac Cleaner & Disk Space Analyzer",
  description:
    "Free and open source (MIT) Mac cleaner. Clean Mac storage, free up disk space, find duplicate files, and remove junk on macOS — no subscription, no license key, no telemetry. The open-source CleanMyMac alternative, built in native Swift. Source on GitHub.",
  keywords: [
    "mac cleaner",
    "free mac cleaner",
    "open source mac cleaner",
    "mac cleaner github",
    "mac space cleaner",
    "clean mac",
    "disk space analyzer mac",
    "cleanmymac alternative",
    "cleanmymac free alternative",
    "mac storage cleaner",
    "free up mac space",
    "mac junk cleaner",
    "duplicate file finder mac",
    "large file finder mac",
    "system cleaner mac",
    "mac disk cleaner",
    "optimize mac storage",
    "mac cleanup app",
    "best mac cleaner",
    "best free mac cleaner",
    "swift macos app open source",
    "developer junk cleaner mac",
    "space lens treemap mac"
  ],
  alternates: {
    canonical: "https://maccleanerpro.com/",
  },
  openGraph: {
    title: "Mac Cleaner Pro — Free, Open Source Mac Cleaner",
    description:
      "Free and open source (MIT) Mac cleaner and disk space analyzer. No subscription, no license key, no telemetry. Source on GitHub.",
    url: "https://maccleanerpro.com/",
    type: "website",
    siteName: "Mac Cleaner Pro",
  },
  twitter: {
    card: "summary_large_image",
    title: "Mac Cleaner Pro — Free, Open Source Mac Cleaner",
    description: "Free and open source (MIT) Mac cleaner. No subscription, no license key. Best CleanMyMac alternative.",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
    },
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
        <Support />
        <BuiltInPublicTimeline />
        <FAQ />
        <SystemRequirements />
        <FooterCTA />
      </main>
      <Footer />
    </>
  );
}
