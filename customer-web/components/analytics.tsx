"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import Script from "next/script";

declare global {
  interface Window {
    dataLayer?: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

const configuredMeasurementId = process.env.NEXT_PUBLIC_GA_ID;
const measurementId =
  configuredMeasurementId && /^G-[A-Z0-9]+$/.test(configuredMeasurementId)
    ? configuredMeasurementId
    : undefined;

export function Analytics() {
  const pathname = usePathname();
  const [allowed, setAllowed] = useState(false);

  useEffect(() => {
    setAllowed(navigator.doNotTrack !== "1");
  }, []);

  useEffect(() => {
    if (!allowed || !measurementId || !window.gtag) return;
    window.gtag("config", measurementId, {
      page_path: pathname,
      anonymize_ip: true,
    });
  }, [allowed, pathname]);

  if (!allowed || !measurementId) return null;

  return (
    <>
      <Script
        src={`https://www.googletagmanager.com/gtag/js?id=${measurementId}`}
        strategy="afterInteractive"
      />
      <Script id="wasabi-analytics" strategy="afterInteractive">
        {`window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments)}window.gtag=gtag;gtag('js',new Date());gtag('config','${measurementId}',{anonymize_ip:true});`}
      </Script>
    </>
  );
}
