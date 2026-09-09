"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Plus } from "lucide-react";
import { toast } from "sonner";

import { FoodImage } from "@/components/food-image";
import { useMenu } from "@/lib/api/queries/menu";
import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";
import type { MenuItem } from "@/types";

export function MenuSection() {
  const { data: categories, isLoading, isError, refetch } = useMenu();
  const [active, setActive] = useState<string | null>(null);

  const scrollTo = (id: string) => {
    setActive(id);
    document
      .getElementById(`cat-${id}`)
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <section id="menu" className="mx-auto max-w-[1280px] px-4 pt-14 sm:px-6 lg:px-10">
      <div className="mb-6 flex items-end justify-between gap-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[var(--brand)]">
            The menu
          </p>
          <h2 className="font-display text-[clamp(1.9rem,3.4vw,2.9rem)] font-black leading-tight tracking-tight">
            Pick your momos
          </h2>
        </div>
      </div>

      {/* Category nav */}
      {categories && categories.length > 0 && (
        <div className="sticky top-[68px] z-[90] -mx-4 mb-6 border-y border-[var(--border)] bg-[color-mix(in_srgb,var(--background)_90%,transparent)] px-4 py-3 backdrop-blur-md">
          <div className="flex gap-2 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {categories.map((c) => (
              <button
                key={c.id}
                onClick={() => scrollTo(c.id)}
                className={`flex-none rounded-full border px-4 py-2 text-sm font-semibold transition-colors ${
                  active === c.id
                    ? "border-[var(--brand)] bg-[var(--brand)] text-white"
                    : "border-[var(--border)] bg-[var(--surface)] text-[var(--foreground-dim)] hover:text-[var(--foreground)]"
                }`}
              >
                {c.name}
              </button>
            ))}
          </div>
        </div>
      )}

      {isLoading && <MenuSkeleton />}

      {isError && (
        <div className="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--surface)] p-8 text-center">
          <p className="text-sm text-[var(--foreground-dim)]">
            We couldn&apos;t load the menu just now.
          </p>
          <button
            onClick={() => refetch()}
            className="mt-3 text-sm font-semibold text-[var(--brand)] underline underline-offset-4"
          >
            Try again
          </button>
        </div>
      )}

      {categories?.map((cat) => (
        <div key={cat.id} id={`cat-${cat.id}`} className="scroll-mt-32 pb-4">
          <h3 className="mb-4 mt-8 font-display text-2xl font-bold tracking-tight">
            {cat.name}
          </h3>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {cat.items.map((item, i) => (
              <ItemCard key={item.id} item={item} index={i} />
            ))}
          </div>
        </div>
      ))}

      {categories?.length === 0 && (
        <p className="py-16 text-center text-sm text-[var(--foreground-dim)]">
          The menu is being prepared. Please check back soon.
        </p>
      )}
    </section>
  );
}

function ItemCard({ item, index }: { item: MenuItem; index: number }) {
  const add = useCartStore((s) => s.add);
  return (
    <motion.article
      initial={{ opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-40px" }}
      transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1], delay: (index % 3) * 0.05 }}
      className="group flex flex-col overflow-hidden rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--surface)] shadow-[var(--shadow-xs)] transition-shadow duration-300 hover:shadow-[var(--shadow-md)]"
    >
      <div className="relative aspect-[4/3] overflow-hidden">
        <FoodImage
          src={item.imageUrl}
          alt={item.name}
          className="h-full w-full transition-transform duration-500 group-hover:scale-[1.04]"
        />
      </div>
      <div className="flex flex-1 flex-col p-4">
        <h4 className="font-display text-lg font-bold leading-snug">{item.name}</h4>
        {item.description && (
          <p className="mt-1 line-clamp-2 text-[13px] leading-relaxed text-[var(--foreground-dim)]">
            {item.description}
          </p>
        )}
        <div className="mt-4 flex items-center justify-between">
          <span className="font-display text-xl font-black tabular-nums">
            {formatTk(item.price)}
          </span>
          <button
            aria-label={`Add ${item.name} to cart`}
            onClick={() => {
              add(item, [], 1);
              toast.success(`${item.name} added`);
            }}
            className="grid h-11 w-11 place-items-center rounded-[12px] bg-[var(--brand)] text-white transition-[background-color,transform] duration-150 hover:bg-[var(--brand-hover)] active:scale-90"
          >
            <Plus className="h-5 w-5" />
          </button>
        </div>
      </div>
    </motion.article>
  );
}

function MenuSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: 6 }).map((_, i) => (
        <div
          key={i}
          className="h-72 animate-pulse rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--surface-sunken)]"
        />
      ))}
    </div>
  );
}
