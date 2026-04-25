import type { Metadata } from "next";
import { BuiltInPublicTimeline } from "@/components/BuiltInPublicTimeline";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Changelog · Built in public",
  description:
    "Every milestone from spec to ship — visible. Mac Cleaner Pro built-in-public version log.",
  alternates: { canonical: `https://${brand.domain}/changelog/` },
};

export default function ChangelogPage() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 100 }}>
        <BuiltInPublicTimeline />
      </main>
      <Footer />
    </>
  );
}
