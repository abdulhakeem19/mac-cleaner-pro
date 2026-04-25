import type { Metadata } from "next";
import { Geist, JetBrains_Mono } from "next/font/google";
import Script from "next/script";
import { ThemeProvider, themeBootScript } from "@/components/ThemeProvider";
import { brand, pricing } from "@/content/site";
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
    default: `${brand.name} — Reclaim disk space on your Mac`,
    template: `%s · ${brand.name}`,
  },
  description: brand.tagline,
  applicationName: brand.name,
  authors: [{ name: brand.name }],
  keywords: [
    "mac cleaner",
    "mac cleaner pro",
    "macos cleaner",
    "disk space cleaner mac",
    "free up disk space",
    "uninstall mac apps",
    "xcode derived data cleaner",
    "duplicate finder mac",
    "indie mac app",
  ],
  openGraph: {
    type: "website",
    siteName: brand.name,
    title: `${brand.name} — Reclaim disk space on your Mac`,
    description: brand.tagline,
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

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: brand.name,
  applicationCategory: "UtilitiesApplication",
  operatingSystem: "macOS 13+",
  description: brand.tagline,
  url: `https://${brand.domain}`,
  offers: pricing.plans.map((p) => ({
    "@type": "Offer",
    name: p.name,
    price: p.usd.replace("$", ""),
    priceCurrency: "USD",
    availability: "https://schema.org/InStock",
  })),
  publisher: { "@type": "Organization", name: brand.name },
};

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
        <ThemeProvider>{children}</ThemeProvider>
        <Script
          id="ld-json"
          type="application/ld+json"
          strategy="beforeInteractive"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </body>
    </html>
  );
}
