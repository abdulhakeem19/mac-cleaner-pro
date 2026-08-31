import type { Metadata } from "next";
import { Geist, JetBrains_Mono } from "next/font/google";
import Script from "next/script";
import { ThemeProvider, themeBootScript } from "@/components/ThemeProvider";
import { MotionProvider } from "@/components/MotionProvider";
import { PaddleScript } from "@/components/PaddleScript";
import { RazorpayScript } from "@/components/RazorpayScript";
import { brand, faq } from "@/content/site";
import "./globals.css";

const geist = Geist({
  subsets: ["latin"],
  variable: "--font-geist",
  display: "swap",
});

const jetbrains = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(`https://${brand.domain}`),
  title: {
    default: `${brand.name} — Free, Open Source Mac Cleaner for macOS`,
    template: `%s · ${brand.name}`,
  },
  description:
    `${brand.name} is a free, open source (MIT) CleanMyMac alternative for macOS. Finally see what's inside System Data, clear caches, remove Xcode junk, find duplicates, uninstall apps completely. Native Swift, privacy-first, no subscription, no license key. Source on GitHub.`,
  applicationName: brand.name,
  authors: [{ name: brand.name }],
  keywords: [
    // Primary
    "mac cleaner",
    "mac cleaner pro",
    "best mac cleaner",
    "free mac cleaner",
    "open source mac cleaner",
    "mac disk cleaner",
    "mac space cleaner",
    "mac storage cleaner",
    "mac cache cleaner",
    "mac cleaning app",
    "mac junk cleaner",
    "clean mac disk space",
    "free up disk space mac",
    // Open source cluster
    "open source mac app",
    "open source macos utility",
    "mac cleaner github",
    "mit license mac app",
    "open source disk cleaner",
    "swift open source macos app",
    "free and open source mac cleaner",
    "self hosted mac cleaner",
    // Secondary
    "mac disk space optimizer",
    "macos cleaner app",
    "mac system cleaner",
    "reclaim disk space mac",
    "clear cache mac",
    "mac log cleaner",
    "clean mac caches",
    "mac cleanup utility",
    "mac disk space analyzer",
    "mac performance optimizer",
    "duplicate file finder mac",
    "memory manager mac",
    "treemap disk usage mac",
    // Long-tail
    "xcode derived data cleaner mac",
    "developer junk cleaner mac",
    "node_modules cleaner mac",
    "uninstall apps mac completely",
    "mac large file finder",
    "mac old file cleaner",
    "mac app uninstaller",
    "mac browser cache cleaner",
    "indie mac cleaner",
    "privacy mac cleaner",
    "no subscription mac cleaner",
    "free mac cleaner no subscription",
    "mac cleaner without subscription",
    "alternative to cleanmymac",
    "cleanmymac free alternative",
    "best free mac cleaner 2025",
    "mac disk space full",
    // System Data + competitor-alternative cluster (research-validated)
    "system data mac",
    "what is system data mac",
    "mac system data cleaner",
    "clear system data mac",
    "cleanmymac alternative",
    "daisydisk alternative",
    "mac cleaner no subscription",
    "mac disk analyzer and cleaner",
    "system data taking up space mac",
    "how to reduce system data mac",
  ],
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  openGraph: {
    type: "website",
    siteName: brand.name,
    title: `${brand.name} — Free, Open Source Mac Cleaner for macOS`,
    description:
      `${brand.name} is a free, open source (MIT) CleanMyMac alternative for macOS. Finally see what's inside System Data, clear caches, remove Xcode junk, find duplicates, uninstall apps completely. Native Swift, privacy-first, no subscription. Source on GitHub.`,
    url: `https://${brand.domain}`,
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: brand.name,
    description: brand.tagline,
  },
  alternates: { canonical: `https://${brand.domain}` },
  category: "utilities",
};

const jsonLdSchemas = [
  // Schema 1 — Enhanced SoftwareApplication
  {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: brand.name,
    alternateName: ["Mac Cleaner", "Mac Space Cleaner", "Mac Disk Cleaner"],
    applicationCategory: "UtilitiesApplication",
    applicationSubCategory: "DiskCleaner",
    operatingSystem: "macOS 13+",
    description:
      "Free, open source (MIT) Mac disk cleaner. Free up disk space, clear caches, remove Xcode DerivedData and dependency junk, find duplicates, uninstall apps with leftover removal. Native Swift, no telemetry, no subscription.",
    url: `https://${brand.domain}`,
    downloadUrl: `https://${brand.domain}/download/`,
    softwareVersion: brand.version,
    releaseNotes: `https://${brand.domain}/changelog/`,
    screenshot: `https://${brand.domain}/opengraph-image.png`,
    license: "https://github.com/vunexolabs/mac-cleaner-pro/blob/main/LICENSE",
    isAccessibleForFree: true,
    featureList: [
      "Smart Scan — one-click disk cleanup",
      "Large & Old File Finder",
      "Developer Junk scanner (node_modules, DerivedData, .gradle)",
      "Duplicate Finder — hash-based with smart auto-select",
      "Space Lens — treemap + sunburst disk visualizer",
      "Memory Manager — live RAM gauge and Quick Free",
      "App Uninstaller with leftover removal",
      "Browser cache cleaner (Chrome, Safari, Firefox)",
      "System and user cache cleaner",
      "Trash-first deletion with 30-day undo",
      "Activity log",
      "No telemetry, fully on-device",
      "Free and open source (MIT license)",
    ],
    offers: {
      "@type": "Offer",
      name: "Mac Cleaner Pro",
      price: "0",
      priceCurrency: "USD",
      description: "Free and open source — no license required",
      availability: "https://schema.org/InStock",
    },
    publisher: {
      "@type": "Organization",
      name: brand.name,
      url: `https://${brand.domain}`,
    },
  },
  // Schema 2 — WebSite
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: brand.name,
    url: `https://${brand.domain}`,
    description: "Best Mac disk space cleaner and cache optimizer for macOS",
    potentialAction: {
      "@type": "SearchAction",
      target: {
        "@type": "EntryPoint",
        urlTemplate: `https://${brand.domain}/?q={search_term_string}`,
      },
      "query-input": "required name=search_term_string",
    },
  },
  // Schema 3 — FAQPage
  {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faq.items.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.a,
      },
    })),
  },
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${geist.variable} ${jetbrains.variable}`}
      suppressHydrationWarning
    >
      <head>
        {/* Pre-hydration theme boot. Runs before React mounts so we never flash
            the wrong palette during first paint. */}
        <script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
      </head>
      <body>
        <MotionProvider>
          <ThemeProvider>{children}</ThemeProvider>
        </MotionProvider>
        {process.env.NEXT_PUBLIC_PADDLE_VENDOR_ID && (
          <PaddleScript vendorId={process.env.NEXT_PUBLIC_PADDLE_VENDOR_ID} />
        )}
        {process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID && <RazorpayScript />}
        <Script
          id="ld-json"
          type="application/ld+json"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdSchemas) }}
        />
      </body>
    </html>
  );
}
