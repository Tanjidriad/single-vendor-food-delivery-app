import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3001";
  return {
    rules: [
      {
        userAgent: "*",
        allow: ["/", "/menu", "/offers", "/privacy", "/terms"],
        disallow: ["/account", "/checkout", "/orders", "/notifications", "/favorites", "/api"],
      },
    ],
    sitemap: `${base.replace(/\/$/, "")}/sitemap.xml`,
  };
}
