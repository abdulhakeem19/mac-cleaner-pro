import type { MetadataRoute } from "next";
import { brand } from "@/content/site";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = `https://${brand.domain}`;
  const releaseDate = new Date("2026-04-26");
  return [
    { url: `${base}/`, lastModified: new Date("2026-04-26"), changeFrequency: "weekly", priority: 1.0 },
    { url: `${base}/install/`, lastModified: releaseDate, changeFrequency: "monthly", priority: 0.8 },
    { url: `${base}/pricing/`, lastModified: releaseDate, changeFrequency: "monthly", priority: 0.9 },
    { url: `${base}/changelog/`, lastModified: releaseDate, changeFrequency: "weekly", priority: 0.7 },
    { url: `${base}/terms/`, lastModified: releaseDate, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/privacy/`, lastModified: releaseDate, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/refund/`, lastModified: releaseDate, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/contact/`, lastModified: releaseDate, changeFrequency: "yearly", priority: 0.5 },
  ];
}
