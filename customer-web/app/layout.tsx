import type { Metadata, Viewport } from "next";
import { Archivo_Black, Fraunces, Inter } from "next/font/google";
import { BrandToaster } from "@/components/ui/toast";

import { QueryProvider } from "@/providers/query-provider";
import { AuthBootstrap } from "@/components/auth-bootstrap";
import { Analytics } from "@/components/analytics";
import "./globals.css";

const siteUrl = new URL(
  process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3001"
);

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

// Editorial high-contrast display face for headlines (doc §6).
const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  display: "swap",
  axes: ["opsz", "SOFT", "WONK"],
});

const archivoBlack = Archivo_Black({
  subsets: ["latin"],
  variable: "--font-archivo-black",
  weight: "400",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: siteUrl,
  title: {
    default: "Wasabi — Momo delivery and pickup",
    template: "%s | Wasabi",
  },
  description:
    "Explore the Wasabi menu and choose delivery or pickup from Wasabi Momo House.",
  applicationName: "Wasabi",
  keywords: ["momo", "food delivery", "pickup", "Dhaka", "Wasabi"],
  openGraph: {
    type: "website",
    url: "/",
    siteName: "Wasabi",
    title: "Wasabi — Momo delivery and pickup",
    description: "Fresh momo for delivery or pickup, ordered directly from Wasabi.",
    images: [{ url: "/img/hero.jpg", width: 1200, height: 630, alt: "Wasabi momo" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Wasabi — Momo delivery and pickup",
    description: "Fresh momo for delivery or pickup, ordered directly from Wasabi.",
    images: ["/img/hero.jpg"],
  },
  robots: { index: true, follow: true },
  manifest: "/manifest.webmanifest",
  icons: { icon: "/icon.svg" },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#d21f3c",
  colorScheme: "light dark",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${fraunces.variable} ${archivoBlack.variable}`}
    >
      <body>
        <QueryProvider>
          <AuthBootstrap />
          {children}
        </QueryProvider>
        <Analytics />
        <BrandToaster />
      </body>
    </html>
  );
}
