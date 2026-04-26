import type { MetadataRoute } from "next";
import { brand } from "@/content/site";

export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/download/"] }],
    sitemap: `https://${brand.domain}/sitemap.xml`,
  };
}
