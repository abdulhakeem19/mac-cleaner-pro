import type { Metadata } from "next";
import { Geist, JetBrains_Mono } from "next/font/google";
import Script from "next/script";
import { ThemeProvider, themeBootScript } from "@/components/ThemeProvider";
import { MotionProvider } from "@/components/MotionProvider";
import { PaddleScript } from "@/components/PaddleScript";
import { RazorpayScript } from "@/components/RazorpayScript";
import { brand, faq, pricing } from "@/content/site";
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
    default: `${brand.name} — Best Mac Disk Space Cleaner for macOS`,
    template: `%s · ${brand.name}`,
  },
  description:
    `${brand.name} is the honest CleanMyMac alternative for macOS. Finally see what's inside System Data, clear caches, remove Xcode junk, uninstall apps completely. Native Swift, privacy-first, pay-once.`,
  applicationName: brand.name,
  authors: [{ name: brand.name }],
  keywords: [
    // Primary
    "mac cleaner",
    "mac cleaner pro",
    "best mac cleaner",
    "mac disk cleaner",
    "mac space cleaner",
    "mac storage cleaner",
    "mac cache cleaner",
    "free mac cleaner",
    "mac cleaning app",
    "mac junk cleaner",
    "clean mac disk space",
    "free up disk space mac",
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
    // Long-tail
    "xcode derived data cleaner mac",
    "uninstall apps mac completely",
    "mac large file finder",
    "mac old file cleaner",
    "mac app uninstaller",
    "mac browser cache cleaner",
    "indie mac cleaner",
    "privacy mac cleaner",
    "no subscription mac cleaner",
    "pay once mac cleaner",
    "mac cleaner without subscription",
    "alternative to cleanmymac",
    "mac disk cleaner free trial",
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
    title: `${brand.name} — Best Mac Disk Space Cleaner for macOS`,
    description:
      `${brand.name} is the honest CleanMyMac alternative for macOS. Finally see what's inside System Data, clear caches, remove Xcode junk, uninstall apps completely. Native Swift, privacy-first, pay-once.`,
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
      "Privacy-first Mac disk cleaner. Free up disk space, clear caches, remove Xcode DerivedData, uninstall apps with leftover removal. Native Swift, no telemetry, pay-once.",
    url: `https://${brand.domain}`,
    downloadUrl: `https://${brand.domain}/download/`,
    softwareVersion: brand.version,
    releaseNotes: `https://${brand.domain}/changelog/`,
    screenshot: `https://${brand.domain}/opengraph-image.png`,
    featureList: [
      "Smart Scan — one-click disk cleanup",
      "Large & Old File Finder",
      "App Uninstaller with leftover removal",
      "Xcode DerivedData cleaner",
      "Browser cache cleaner (Chrome, Safari, Firefox)",
      "System and user cache cleaner",
      "Trash-first deletion with 30-day undo",
      "Activity log",
      "No telemetry, fully on-device",
    ],
    offers: pricing.plans.map((p) => ({
      "@type": "Offer",
      name: p.name,
      price: p.usd.replace("$", ""),
      priceCurrency: "USD",
      description: p.key === "free" ? `${pricing.trialDays}-day free trial` : p.usdSub,
      availability: "https://schema.org/InStock",
    })),
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
