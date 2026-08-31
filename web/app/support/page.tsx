import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { Support } from "@/components/Support";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Support Mac Cleaner Pro — Free & Open Source",
  description:
    "Mac Cleaner Pro is free and open source (MIT). Donations via GitHub Sponsors, Open Collective, or Ko-fi fund the Apple Developer Program fee, hosting, and ongoing maintenance.",
  alternates: { canonical: `https://${brand.domain}/support/` },
};

export default function SupportPage() {
  return (
    <>
      <Nav />
      <main className="pt-24 md:pt-32" style={{ paddingBottom: 40 }}>
        <Support />
      </main>
      <Footer />
    </>
  );
}
