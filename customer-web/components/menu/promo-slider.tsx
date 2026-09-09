"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { ArrowRight, TicketPercent } from "lucide-react";

import { usePromoBanners } from "@/lib/api/queries/menu";
import { placeholderFood } from "@/lib/placeholder-images";

const AUTOPLAY_MS = 6000;

export function PromoSlider() {
  const { data, isLoading } = usePromoBanners();
  const banners = data ?? [];
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (banners.length <= 1) return;
    const timer = window.setInterval(
      () => setIndex((current) => (current + 1) % banners.length),
      AUTOPLAY_MS
    );
    return () => window.clearInterval(timer);
  }, [banners.length]);

  if (isLoading) {
    return (
      <div className="mx-auto max-w-[1440px] animate-pulse bg-[var(--menu-red)]/15 px-4 py-12 sm:my-6 sm:h-28 sm:px-6 lg:px-10" />
    );
  }
  if (banners.length === 0) return null;

  const active = banners[index] ?? banners[0];
  const content = (
    <div className="wasabi-ticket relative grid min-h-[98px] grid-cols-[auto_minmax(0,1fr)_68px] items-center gap-3 overflow-hidden bg-[var(--menu-red)] px-6 py-4 text-white sm:min-h-[112px] sm:grid-cols-[auto_minmax(0,1fr)_110px] sm:gap-5 sm:px-10 lg:px-12">
      <TicketPercent className="h-8 w-8 sm:h-10 sm:w-10" strokeWidth={1.7} />
      <AnimatePresence mode="wait">
        <motion.div
          key={active.id}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -8 }}
          className="min-w-0 border-l border-white/35 pl-3 sm:pl-5"
        >
          <p className="text-[9px] font-black uppercase tracking-[0.2em] text-white/70 sm:text-[10px]">
            Kitchen special
          </p>
          <p className="mt-1 line-clamp-2 text-sm font-black leading-tight sm:text-lg">
            {active.title}
          </p>
        </motion.div>
      </AnimatePresence>
      <div className="relative h-16 overflow-hidden border border-white/25 sm:h-20">
        <Image
          src={active.imageUrl || placeholderFood(active.title)}
          alt=""
          fill
          sizes="110px"
          className="object-cover"
        />
        <span className="absolute inset-0 grid place-items-center bg-black/20">
          <ArrowRight className="h-5 w-5" />
        </span>
      </div>
      {banners.length > 1 && (
        <span className="absolute bottom-2 left-[72px] flex gap-1 sm:left-[100px]">
          {banners.map((banner, dotIndex) => (
            <button
              key={banner.id}
              type="button"
              onClick={(event) => {
                event.preventDefault();
                setIndex(dotIndex);
              }}
              aria-label={`Show offer ${dotIndex + 1}`}
              className={`h-1 transition-all ${dotIndex === index ? "w-5 bg-white" : "w-1.5 bg-white/45"}`}
            />
          ))}
        </span>
      )}
    </div>
  );

  return (
    <section className="mx-auto max-w-[1440px] sm:px-6 sm:pt-6 lg:px-10">
      {active.linkUrl ? (
        <Link href={active.linkUrl} className="block focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200">
          {content}
        </Link>
      ) : (
        content
      )}
    </section>
  );
}
