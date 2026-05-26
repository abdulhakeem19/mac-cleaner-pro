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
  title: "Mac Cleaner Pro — Best Mac Cleaner & Disk Space Analyzer for macOS",
  description:
    "Clean Mac storage, free up disk space, and remove junk files on macOS. The best Mac cleaner app alternative to CleanMyMac. Find large files, duplicate files, and system junk. Native Mac space cleaner with no subscription.",
  keywords: [
    "mac cleaner",
    "mac space cleaner",
    "clean mac",
    "disk space analyzer mac",
    "cleanmymac alternative",
    "mac storage cleaner",
    "free up mac space",
    "mac junk cleaner",
    "duplicate file finder mac",
    "large file finder mac",
    "system cleaner mac",
    "mac disk cleaner",
    "optimize mac storage",
    "mac cleanup app",
    "best mac cleaner"
  ],
  alternates: {
    canonical: "https://maccleanerpro.com/",
  },
  openGraph: {
    title: "Mac Cleaner Pro — Best Mac Cleaner & Disk Space Analyzer",
    description:
      "Clean Mac storage, free up disk space, and remove junk files. The best Mac cleaner app alternative to CleanMyMac. No subscription required.",
    url: "https://maccleanerpro.com/",
    type: "website",
    siteName: "Mac Cleaner Pro",
  },
  twitter: {
    card: "summary_large_image",
    title: "Mac Cleaner Pro — Best Mac Cleaner & Disk Space Analyzer",
    description: "Clean Mac storage, free up disk space, and remove junk files. Best CleanMyMac alternative.",
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
