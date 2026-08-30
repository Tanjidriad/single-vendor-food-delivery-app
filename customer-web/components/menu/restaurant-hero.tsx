"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { Bike, Clock3, ShoppingBag } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { useRestaurant } from "@/lib/api/queries/menu";
import { HERO_PHOTO } from "@/lib/placeholder-images";
import { RESTAURANT_INFO, getOpenStatus } from "@/lib/restaurant-info";

export function RestaurantHero() {
  const { data: restaurant } = useRestaurant();
  const name = restaurant?.name ?? RESTAURANT_INFO.name;
  const hours = restaurant?.operatingHours?.length
    ? restaurant.operatingHours
    : RESTAURANT_INFO.operatingHours;
  const status = getOpenStatus(hours);
  const prepMinutes = restaurant?.settings?.defaultPrepMinutes;

  return (
    <section className="overflow-hidden border-b border-black/10 bg-[var(--menu-rice)]">
      <div className="mx-auto grid max-w-[1440px] lg:grid-cols-[0.9fr_1.1fr] lg:px-10 lg:py-8">
        <div className="relative min-h-[300px] overflow-hidden px-5 pb-8 pt-10 sm:min-h-[350px] sm:px-8 sm:pb-10 sm:pt-14 lg:min-h-[470px] lg:px-10 lg:py-16 xl:px-14">
          <motion.div
            aria-hidden="true"
            initial={{ scale: 0.82, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.72, ease: [0.16, 1, 0.3, 1] }}
            className="absolute -right-12 top-8 h-56 w-56 rounded-full bg-[var(--menu-red)] sm:-right-8 sm:top-10 sm:h-72 sm:w-72 lg:right-0 lg:top-1/2 lg:h-[360px] lg:w-[360px] lg:-translate-y-1/2"
          />
          <motion.div
            aria-hidden="true"
            initial={{ x: 42, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.12, duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
            className="absolute right-0 top-[88px] z-10 text-[var(--menu-ink)] sm:right-5 sm:top-[116px] lg:right-7 lg:top-1/2 lg:-translate-y-1/2"
          >
            <ToriiMark className="h-32 w-40 sm:h-40 sm:w-52 lg:h-52 lg:w-64" />
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.08, duration: 0.55 }}
            className="relative z-20 max-w-[235px] sm:max-w-[340px] lg:max-w-[390px]"
          >
            <p className="mb-5 text-[10px] font-black uppercase tracking-[0.2em] text-[var(--menu-red)] sm:text-xs">
              {name}
            </p>
            <h1 className="font-street text-[clamp(3rem,13vw,5.7rem)] leading-[0.9] text-balance">
              Momo,
              <br />
              made loud.
            </h1>
            <span className="mt-6 block h-[3px] w-12 bg-[var(--menu-red)]" />
            <div className="mt-5 flex flex-wrap items-center gap-x-4 gap-y-2 text-[11px] font-black uppercase tracking-[0.08em] sm:text-xs">
              {status && (
                <span className="inline-flex items-center gap-2 text-[var(--menu-red)]">
                  <span className="h-2.5 w-2.5 rounded-full bg-current" />
                  {status.isOpen ? "Open now" : status.label}
                </span>
              )}
              {prepMinutes && (
                <span className="inline-flex items-center gap-1.5 border-l border-black/20 pl-4 dark:border-white/20">
                  <Clock3 className="h-3.5 w-3.5" /> {prepMinutes} min prep
                </span>
              )}
            </div>
          </motion.div>
        </div>

        <motion.div
          initial={{ opacity: 0, scale: 0.98 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.18, duration: 0.62 }}
          className="relative h-[210px] overflow-hidden border-t-4 border-[var(--menu-ink)] sm:h-[300px] lg:h-auto lg:min-h-[470px] lg:border-l-4 lg:border-t-0"
        >
          <Image
            src={HERO_PHOTO}
            alt={`${name} freshly steamed momo`}
            fill
            priority
            sizes="(max-width: 1024px) 100vw, 58vw"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/55 via-transparent to-transparent" />
          <div className="absolute bottom-0 left-0 flex w-full items-center justify-between gap-3 p-4 text-white sm:p-6">
            <span className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.12em]">
              <Bike className="h-4 w-4 text-[#f0c96b]" /> Delivery
            </span>
            <span className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.12em]">
              <ShoppingBag className="h-4 w-4 text-[#f0c96b]" /> Pickup
            </span>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
