import type { NextConfig } from "next";

const isProduction = process.env.NODE_ENV === "production";

function originOf(value: string | undefined): string | null {
  if (!value) return null;
  try {
    return new URL(value).origin;
  } catch {
    return null;
  }
}

const socketOrigin = originOf(process.env.NEXT_PUBLIC_SOCKET_URL);
const socketWebSocketOrigin = socketOrigin?.replace(/^http/, "ws") ?? null;
const imageOrigin = originOf(process.env.NEXT_PUBLIC_IMAGE_ORIGIN);
const connectSources = [
  "'self'",
  socketOrigin,
  socketWebSocketOrigin,
  ...(process.env.NEXT_PUBLIC_GA_ID
    ? ["https://www.google-analytics.com", "https://region1.google-analytics.com"]
    : []),
]
  .filter(Boolean)
  .join(" ");
const imageSources = [
  "'self'",
  "data:",
  "blob:",
  "https://res.cloudinary.com",
  "https://images.unsplash.com",
  imageOrigin,
  ...(process.env.NEXT_PUBLIC_GA_ID ? ["https://www.google-analytics.com"] : []),
]
  .filter(Boolean)
  .join(" ");

const contentSecurityPolicy = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${isProduction ? "" : " 'unsafe-eval'"}${process.env.NEXT_PUBLIC_GA_ID ? " https://www.googletagmanager.com" : ""}`,
  "style-src 'self' 'unsafe-inline'",
  `img-src ${imageSources}`,
  "font-src 'self' data:",
  `connect-src ${connectSources}`,
  "frame-src https://www.openstreetmap.org",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "manifest-src 'self'",
  "worker-src 'self' blob:",
  "frame-ancestors 'none'",
  ...(isProduction ? ["upgrade-insecure-requests"] : []),
].join("; ");

const remotePatterns: NonNullable<NextConfig["images"]>["remotePatterns"] = [
  { protocol: "https", hostname: "res.cloudinary.com" },
  { protocol: "https", hostname: "images.unsplash.com" },
];

if (imageOrigin) {
  const imageUrl = new URL(imageOrigin);
  remotePatterns?.push({
    protocol: imageUrl.protocol.replace(":", "") as "http" | "https",
    hostname: imageUrl.hostname,
    port: imageUrl.port,
  });
}

if (!isProduction) {
  remotePatterns?.push({ protocol: "http", hostname: "localhost" });
}

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "standalone",
  poweredByHeader: false,
  images: { remotePatterns },
  async headers() {
    const headers = [
      { key: "Content-Security-Policy", value: contentSecurityPolicy },
      { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      { key: "X-Content-Type-Options", value: "nosniff" },
      { key: "X-Frame-Options", value: "DENY" },
      {
        key: "Permissions-Policy",
        value: "camera=(), microphone=(), geolocation=(self)",
      },
    ];
    if (isProduction) {
      headers.push({
        key: "Strict-Transport-Security",
        value: "max-age=31536000; includeSubDomains",
      });
    }
    return [{ source: "/:path*", headers }];
  },
};

export default nextConfig;
