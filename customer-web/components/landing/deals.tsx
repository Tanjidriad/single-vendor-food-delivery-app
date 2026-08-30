"use client";

import Link from "next/link";
import Image from "next/image";
import { motion } from "framer-motion";
import { ArrowRight, Plus } from "lucide-react";

import { useFeaturedMenu } from "@/lib/api/queries/menu";
import { placeholderFood } from "@/lib/placeholder-images";
import { formatTk } from "@/lib/utils";

const ease = [0.16, 1, 0.3, 1] as const;

export function FeaturedMenu() {
  const { data: dishes, isLoading } = useFeaturedMenu();

  if (!isLoading && !dishes?.length) return null;

  return (
    <section className="mx-auto max-w-[1440px] px-4 pt-16 sm:px-6 sm:pt-24 lg:px-10">
      <div className="mb-7 flex items-end justify-between gap-5 border-b-4 border-[var(--menu-ink)] pb-5 sm:mb-9">
        <div>
          <p className="wasabi-page-kicker">Kitchen picks</p>
          <h2 className="font-street mt-3 max-w-[12ch] text-[clamp(2.5rem,7vw,5.2rem)] leading-[0.86]">First out of the steamer.</h2>
          <p className="mt-3 max-w-[46ch] text-sm leading-6 text-[var(--foreground-dim)] sm:text-[15px]">Fresh dishes selected by the Wasabi kitchen.</p>
        </div>
        <Link href="/menu" className="hidden min-h-11 items-center gap-3 border-2 border-[var(--menu-ink)] px-5 text-xs font-black uppercase tracking-[0.08em] transition-colors hover:bg-[var(--menu-ink)] hover:text-[var(--menu-rice)] sm:inline-flex">
          View full menu <ArrowRight className="h-4 w-4" />
        </Link>
      </div>

      <div className="-mx-4 flex snap-x snap-mandatory gap-3 overflow-x-auto px-4 pb-3 [scrollbar-width:none] sm:mx-0 sm:grid sm:grid-cols-2 sm:gap-4 sm:overflow-visible sm:px-0 sm:pb-0 lg:grid-cols-4 [&::-webkit-scrollbar]:hidden">
        {(dishes ?? []).slice(0, 4).map((dish, index) => (
          <motion.div
            key={dish.id}
            initial={{ opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ duration: 0.5, ease, delay: (index % 4) * 0.06 }}
            className="w-[58vw] max-w-[230px] flex-none snap-start sm:w-auto sm:max-w-none"
          >
            <Link href="/menu" className="group relative flex h-full flex-col overflow-hidden border border-black/15 bg-[var(--menu-rice)] text-[var(--menu-ink)] transition-colors hover:border-[var(--menu-red)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200 dark:border-white/15">
              <div className="relative aspect-[5/4] overflow-hidden">
                <Image
                  src={dish.imageUrl || placeholderFood(dish.id)}
                  alt={dish.name}
                  fill
                  sizes="(max-width: 640px) 58vw, (max-width: 1024px) 50vw, 25vw"
                  loading={index === 0 ? "eager" : "lazy"}
                  className="object-cover transition-transform duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:scale-[1.07]"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/30 via-transparent to-transparent" />
              </div>
              <div className="flex flex-1 flex-col p-4 pt-3 sm:p-5 sm:pt-4">
                <div className="flex items-start justify-between gap-3">
                  <h3 className="font-street text-[1.05rem] leading-[1.05] sm:text-[1.2rem]">{dish.name}</h3>
                  <span className="flex-none text-[15px] font-black tabular-nums text-[var(--menu-red)] sm:text-base">{formatTk(dish.price)}</span>
                </div>
                <p className="mt-1.5 line-clamp-2 text-xs leading-5 text-black/50 dark:text-white/50 sm:text-[13px]">{dish.description || "Freshly prepared by Wasabi."}</p>
                <span className="mt-4 inline-flex items-center gap-2 self-start bg-[var(--menu-red)] px-3.5 py-2 text-[10px] font-black uppercase tracking-[0.08em] text-white transition-colors group-hover:bg-[var(--menu-ink)] sm:mt-5">
                  <Plus className="h-3.5 w-3.5" /> Add to order
                </span>
              </div>
            </Link>
          </motion.div>
        ))}
        {isLoading && [0, 1, 2, 3].map((item) => (
          <div key={item} className="h-[320px] w-[58vw] max-w-[230px] flex-none animate-pulse rounded-[14px] bg-[var(--surface-sunken)] sm:w-auto sm:max-w-none" />
        ))}
      </div>

      <Link href="/menu" className="mt-4 inline-flex h-12 w-full items-center justify-center gap-2 border-2 border-[var(--menu-ink)] text-xs font-black uppercase tracking-[0.08em] sm:hidden">
        View full menu <ArrowRight className="h-4 w-4" />
      </Link>
    </section>
  );
}
