"use client";

import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, HandPlatter, Sparkles } from "lucide-react";

import { RESTAURANT_INFO } from "@/lib/restaurant-info";
import { useRestaurant } from "@/lib/api/queries/menu";

const ease = [0.16, 1, 0.3, 1] as const;

const VALUES = [
  { icon: HandPlatter, title: "Folded by hand", body: "Every order, made fresh" },
  { icon: Sparkles, title: "Steamed to order", body: "Never sitting, never stale" },
];

export function BrandStory() {
  const { data: restaurant } = useRestaurant();
  return (
    <section className="mx-auto mt-20 max-w-[1440px] px-4 sm:mt-28 sm:px-6 lg:px-10">
      <div className="grain relative overflow-hidden border-y-4 border-[var(--menu-red)] bg-[var(--menu-bar)] text-white">
        <div className="pointer-events-none absolute -left-24 -top-24 h-80 w-80 rounded-full bg-[radial-gradient(circle,rgba(210,31,60,0.28),transparent_65%)]" />

        <div className="relative grid gap-8 p-6 sm:p-10 lg:grid-cols-[1.05fr_0.95fr] lg:items-center lg:gap-12 lg:p-14">
          {/* Copy */}
          <div>
            <motion.p
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.5, ease }}
              className="flex items-center gap-3 text-[11px] font-bold uppercase tracking-[0.22em] text-[var(--brand)] sm:text-xs"
            >
              Our story
              <span className="h-px w-10 bg-[var(--brand)]/50" />
            </motion.p>

            <motion.h2
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.6, ease, delay: 0.05 }}
              className="font-street mt-5 max-w-[16ch] text-[clamp(2.4rem,7vw,4.5rem)] leading-[0.88]"
            >
              Where great momo meets good moments.
            </motion.h2>

            <motion.p
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.6, ease, delay: 0.12 }}
              className="mt-5 max-w-[52ch] text-[15px] leading-7 text-white/65 sm:text-base"
            >
              {restaurant?.description || RESTAURANT_INFO.description}
            </motion.p>

            <div className="mt-8 flex flex-wrap gap-x-8 gap-y-5">
              {VALUES.map((v) => (
                <div key={v.title} className="flex items-center gap-3">
                  <span className="grid h-11 w-11 flex-none place-items-center bg-[var(--menu-red)] text-white">
                    <v.icon className="h-5 w-5" />
                  </span>
                  <div>
                    <p className="text-sm font-bold">{v.title}</p>
                    <p className="text-xs text-white/50">{v.body}</p>
                  </div>
                </div>
              ))}
            </div>

            <Link
              href="/menu"
              className="group mt-9 inline-flex h-14 items-center justify-center gap-3 bg-white px-7 text-xs font-black uppercase tracking-[0.08em] text-[var(--menu-ink)] transition-colors hover:bg-[var(--menu-red)] hover:text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-white/30"
            >
              Browse the menu
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
            </Link>
          </div>

          {/* Photo */}
          <motion.div
            initial={{ opacity: 0, scale: 0.96 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-60px" }}
            transition={{ duration: 0.7, ease, delay: 0.1 }}
            className="relative aspect-[4/3] w-full overflow-hidden border-2 border-white/20 sm:aspect-[16/11] lg:aspect-[4/3]"
          >
            <Image
              src="/img/momo-bowl.jpg"
              alt="A bowl of Wasabi momo served fresh"
              fill
              sizes="(max-width: 1024px) 100vw, 45vw"
              className="object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[var(--ink)]/45 via-transparent to-transparent" />
          </motion.div>
        </div>
      </div>
    </section>
  );
}
