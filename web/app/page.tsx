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
