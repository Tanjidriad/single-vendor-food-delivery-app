"use client";

import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowDownRight, Bike, Clock3, Radio, ShoppingBag } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { useRestaurant } from "@/lib/api/queries/menu";
import { HERO_PHOTO } from "@/lib/placeholder-images";
import { RESTAURANT_INFO, getOpenStatus } from "@/lib/restaurant-info";

const features = [
  { icon: Bike, label: "Delivery" },
  { icon: ShoppingBag, label: "Pickup" },
  { icon: Radio, label: "Live tracking" },
];

export function LandingHero() {
  const { data: restaurant } = useRestaurant();
  const hours = restaurant?.operatingHours?.length
    ? restaurant.operatingHours
    : RESTAURANT_INFO.operatingHours;
  const status = getOpenStatus(hours);

  return (
    <section className="overflow-hidden border-b-4 border-[var(--menu-ink)]">
      <div className="mx-auto grid max-w-[1440px] lg:grid-cols-[0.92fr_1.08fr] lg:px-10 lg:py-8">
        <div className="relative min-h-[440px] overflow-hidden bg-[var(--menu-rice)] px-5 pb-9 pt-12 sm:min-h-[520px] sm:px-9 sm:pb-12 sm:pt-16 lg:min-h-[610px] lg:px-12 lg:py-16">
          <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ duration: 0.75, ease: [0.16, 1, 0.3, 1] }} className="absolute -right-20 top-16 h-64 w-64 rounded-full bg-[var(--menu-red)] sm:-right-10 sm:h-80 sm:w-80 lg:-right-20 lg:top-1/2 lg:h-[420px] lg:w-[420px] lg:-translate-y-1/2" />
          <motion.div initial={{ x: 35, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: 0.12, duration: 0.65 }} className="absolute -right-4 top-28 z-10 text-[var(--menu-ink)] sm:right-5 sm:top-36 lg:-right-5 lg:top-1/2 lg:-translate-y-1/2">
            <ToriiMark className="h-36 w-44 sm:h-48 sm:w-60 lg:h-64 lg:w-80" />
          </motion.div>

          <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.58 }} className="relative z-20 max-w-[310px] sm:max-w-[440px] lg:max-w-[470px]">
            <p className="wasabi-page-kicker">Wasabi Momo House</p>
            <h1 className="font-street mt-7 text-[clamp(3.6rem,14vw,7.4rem)] leading-[0.79] tracking-[-0.07em]">HOT.<br />FOLDED.<br />FAST.</h1>
            <p className="mt-7 max-w-[35ch] border-l-2 border-[var(--menu-red)] pl-4 text-sm font-semibold leading-6 text-black/55 dark:text-white/55">Hand-folded momo, sent from our steamer to your door—or waiting at the counter.</p>
            <div className="mt-7 flex flex-wrap gap-2">
              <Link href="/menu" className="inline-flex min-h-12 items-center gap-4 bg-[var(--menu-red)] px-5 text-xs font-black uppercase tracking-[0.1em] text-white transition-colors hover:bg-[var(--menu-ink)]">Build an order <ArrowDownRight className="h-4 w-4" /></Link>
              <Link href="#how-it-works" className="inline-flex min-h-12 items-center border-2 border-[var(--menu-ink)] px-5 text-xs font-black uppercase tracking-[0.1em] transition-colors hover:bg-[var(--menu-ink)] hover:text-[var(--menu-rice)]">How it moves</Link>
            </div>
          </motion.div>
        </div>

        <motion.div initial={{ opacity: 0, scale: 0.985 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.12, duration: 0.65 }} className="relative h-[300px] overflow-hidden border-t-4 border-[var(--menu-ink)] sm:h-[430px] lg:h-auto lg:min-h-[610px] lg:border-l-4 lg:border-t-0">
          <Image src={HERO_PHOTO} alt="Fresh Wasabi momo in bamboo steamers" fill priority sizes="(max-width: 1024px) 100vw, 58vw" className="object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/5 to-transparent" />
          <div className="absolute inset-x-0 bottom-0 grid grid-cols-[1fr_auto] items-end gap-5 p-5 text-white sm:p-7">
            <div>
              <p className="text-[9px] font-black uppercase tracking-[0.2em] text-[#f0c96b]">Kitchen signal</p>
              <p className="font-street mt-1 text-2xl uppercase sm:text-3xl">{status?.label ?? "Taking orders"}</p>
            </div>
            {restaurant?.settings?.defaultPrepMinutes && <span className="flex items-center gap-2 border-l border-white/30 pl-4 text-[10px] font-black uppercase tracking-[0.1em]"><Clock3 className="h-4 w-4 text-[#f0c96b]" />{restaurant.settings.defaultPrepMinutes} min prep</span>}
          </div>
        </motion.div>
      </div>

      <div className="bg-[var(--menu-ink)] text-white">
        <div className="mx-auto grid max-w-[1440px] grid-cols-3 lg:px-10">
          {features.map((feature) => <div key={feature.label} className="flex min-h-16 items-center justify-center gap-2 border-r border-white/15 px-2 text-center last:border-r-0 sm:min-h-20 sm:gap-3"><feature.icon className="h-4 w-4 flex-none text-[var(--menu-red)] sm:h-5 sm:w-5" /><span className="text-[9px] font-black uppercase tracking-[0.08em] text-white/70 sm:text-xs">{feature.label}</span></div>)}
        </div>
      </div>
    </section>
  );
}
