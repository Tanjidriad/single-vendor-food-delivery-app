"use client";

import Link from "next/link";
import Image from "next/image";
import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";

import { useMenu } from "@/lib/api/queries/menu";
import { placeholderFood } from "@/lib/placeholder-images";

export function Categories() {
  const { data: menu, isLoading } = useMenu();
  const categories = (menu ?? []).slice(0, 5).map((category) => ({
    id: category.id,
    name: category.name,
    label: `${category.items.length} ${category.items.length === 1 ? "dish" : "dishes"}`,
    image:
      category.items.find((item) => item.imageUrl)?.imageUrl ||
      placeholderFood(category.id),
  }));

  if (!isLoading && categories.length === 0) return null;

  return (
    <section className="mx-auto max-w-[1440px] px-4 pt-20 sm:px-6 sm:pt-28 lg:px-10">
      <div className="mb-7 sm:mb-9">
        <p className="wasabi-page-kicker">Choose your fold</p>
        <h2 className="font-street mt-3 text-[clamp(2.5rem,7vw,5rem)] leading-[0.86]">Find your kind of momo.</h2>
      </div>

      <div className="-mx-4 flex snap-x snap-mandatory gap-2.5 overflow-x-auto px-4 pb-3 [scrollbar-width:none] sm:mx-0 sm:grid sm:grid-cols-2 sm:gap-4 sm:overflow-visible sm:px-0 sm:pb-0 lg:grid-cols-5 [&::-webkit-scrollbar]:hidden">
        {categories.map((category, index) => (
          <motion.div
            key={category.id}
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1], delay: (index % 5) * 0.05 }}
            className="w-[42vw] min-w-[148px] max-w-[180px] flex-none snap-start sm:w-auto sm:min-w-0 sm:max-w-none"
          >
            <Link href="/menu" className="group relative block aspect-[3/4] overflow-hidden border border-black/15 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200 dark:border-white/15">
              <Image src={category.image} alt={category.name} fill sizes="(max-width: 640px) 42vw, (max-width: 1024px) 50vw, 20vw" className="object-cover transition-transform duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:scale-[1.08]" />
              <div className="absolute inset-0 bg-gradient-to-t from-[var(--ink)] via-[color-mix(in_srgb,var(--ink)_35%,transparent)] to-transparent opacity-90" />
              <span className="absolute right-2.5 top-2.5 grid h-8 w-8 place-items-center bg-[var(--menu-red)] text-white transition-transform duration-300 group-hover:translate-x-1 group-hover:-translate-y-1 sm:right-3.5 sm:top-3.5 sm:h-9 sm:w-9"><ArrowUpRight className="h-3.5 w-3.5 sm:h-4 sm:w-4" /></span>
              <div className="absolute inset-x-0 bottom-0 p-3 sm:p-5">
                <span className="mb-1.5 block h-0.5 w-6 rounded-full bg-[var(--mustard)] sm:mb-2.5 sm:w-8" />
                <p className="text-[9px] font-bold uppercase tracking-[0.14em] text-white/55 sm:text-[10px]">{category.label}</p>
                <h3 className="font-street mt-1 text-[0.95rem] leading-[1.05] text-white sm:mt-1.5 sm:text-[1.3rem]">{category.name}</h3>
              </div>
            </Link>
          </motion.div>
        ))}
        {isLoading && [0, 1, 2, 3].map((item) => (
          <div key={item} className="h-[240px] w-[42vw] min-w-[148px] max-w-[180px] flex-none animate-pulse rounded-[14px] bg-[var(--surface-sunken)] sm:w-auto sm:min-w-0 sm:max-w-none" />
        ))}
      </div>
    </section>
  );
}
