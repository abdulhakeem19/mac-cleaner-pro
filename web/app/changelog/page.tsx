import type { Metadata } from "next";
import { BuiltInPublicTimeline } from "@/components/BuiltInPublicTimeline";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Mac Cleaner Pro Changelog — What's New & What's Coming",
  description:
    "Follow the Mac Cleaner Pro built-in-public development log. Every milestone from spec to ship — smart scan, large file finder, app uninstaller, and more.",
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
