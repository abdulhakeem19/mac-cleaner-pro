import type { MetadataRoute } from "next";
import { brand } from "@/content/site";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = `https://${brand.domain}`;
  const now = new Date();
  return [
    { url: `${base}/`, lastModified: now, changeFrequency: "weekly", priority: 1.0 },
    { url: `${base}/install/`, lastModified: now, changeFrequency: "monthly", priority: 0.8 },
    { url: `${base}/pricing/`, lastModified: now, changeFrequency: "monthly", priority: 0.9 },
    { url: `${base}/changelog/`, lastModified: now, changeFrequency: "weekly", priority: 0.7 },
    { url: `${base}/terms/`, lastModified: now, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/privacy/`, lastModified: now, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/refund/`, lastModified: now, changeFrequency: "yearly", priority: 0.4 },
    { url: `${base}/contact/`, lastModified: now, changeFrequency: "yearly", priority: 0.5 },
  ];
}
