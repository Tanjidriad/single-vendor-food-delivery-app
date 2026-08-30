"use client";

import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, LayoutGroup, motion } from "framer-motion";
import { Minus, Plus, Search, SlidersHorizontal, X } from "lucide-react";
import { toast } from "sonner";

import { FoodImage } from "@/components/food-image";
import { FavoriteButton } from "@/components/menu/favorite-button";
import { ItemSheet } from "@/components/menu/item-sheet";
import { useMenu } from "@/lib/api/queries/menu";
import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";
import type { CartLine, MenuCategory, MenuItem } from "@/types";

type MenuSection = MenuCategory & { isPopular?: boolean };

export function MenuBrowser() {
  const { data: categories, isLoading, isError, refetch } = useMenu();
  const [query, setQuery] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const [active, setActive] = useState<string | null>(null);
  const [sheetItem, setSheetItem] = useState<MenuItem | null>(null);

  const sections = useMemo<MenuSection[]>(() => {
    if (!categories) return [];
    const popular = categories
      .flatMap((category) => category.items)
      .filter((item) => item.isFeatured);
    return popular.length
      ? [{ id: "popular", name: "Popular", items: popular, isPopular: true }, ...categories]
      : categories;
  }, [categories]);

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return sections;
    return sections
      .map((section) => ({
        ...section,
        items: section.items.filter(
          (item) =>
            item.name.toLowerCase().includes(needle) ||
            (item.description ?? "").toLowerCase().includes(needle)
        ),
      }))
      .filter((section) => section.items.length > 0);
  }, [query, sections]);

  useEffect(() => {
    if (!active && sections[0]) setActive(sections[0].id);
  }, [active, sections]);

  useEffect(() => {
    const elements = sections
      .map((section) => document.getElementById(`menu-section-${section.id}`))
      .filter((element): element is HTMLElement => !!element);
    if (!elements.length) return;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (visible) setActive(visible.target.id.replace("menu-section-", ""));
      },
      { rootMargin: "-145px 0px -58% 0px", threshold: [0.05, 0.25, 0.6] }
    );
    elements.forEach((element) => observer.observe(element));
    return () => observer.disconnect();
  }, [sections]);

  function scrollTo(id: string) {
    setActive(id);
    document
      .getElementById(`menu-section-${id}`)
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  return (
    <section id="menu-list" className="mx-auto max-w-[1440px] pt-3 sm:px-6 sm:pt-8 lg:px-10">
      <div className="sticky top-[68px] z-[90] border-y-4 border-[var(--menu-ink)] bg-[var(--menu-rice)] sm:top-[76px] sm:border-x sm:border-y-2">
        <div className="flex items-stretch overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <LayoutGroup id="menu-categories">
            {sections.map((section) => (
              <button
                key={section.id}
                type="button"
                onClick={() => scrollTo(section.id)}
                className="relative min-w-[104px] flex-none border-r border-black/15 px-5 py-4 text-left focus-visible:z-10 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-inset focus-visible:ring-red-200 sm:min-w-[132px] sm:px-6"
              >
                <span className={`block text-[9px] font-black tracking-[0.18em] ${active === section.id ? "text-[var(--menu-red)]" : "text-black/38 dark:text-white/38"}`}>
                  {String(sections.indexOf(section) + 1).padStart(2, "0")}
                </span>
                <span className="mt-1 block text-[12px] font-black uppercase tracking-[0.08em] sm:text-[13px]">
                  {section.name}
                </span>
                {active === section.id && (
                  <motion.span
                    layoutId="menu-category-marker"
                    className="absolute inset-x-0 bottom-0 h-1 bg-[var(--menu-red)]"
                  />
                )}
              </button>
            ))}
          </LayoutGroup>
          <button
            type="button"
            onClick={() => setSearchOpen((open) => !open)}
            aria-expanded={searchOpen}
            aria-controls="menu-search"
            className="sticky right-0 ml-auto grid min-w-[64px] flex-none place-items-center border-l border-black/15 bg-[var(--menu-rice)] text-[var(--menu-ink)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-inset focus-visible:ring-red-200 sm:min-w-[76px]"
          >
            {searchOpen ? <X className="h-5 w-5" /> : <Search className="h-5 w-5" />}
            <span className="sr-only">{searchOpen ? "Close search" : "Search menu"}</span>
          </button>
        </div>
        <AnimatePresence initial={false}>
          {searchOpen && (
            <motion.div
              id="menu-search"
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="overflow-hidden border-t border-black/15"
            >
              <label className="relative block p-3 sm:p-4">
                <Search className="pointer-events-none absolute left-7 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-black/40 sm:left-8 dark:text-white/40" />
                <span className="sr-only">Search dishes</span>
                <input
                  autoFocus
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder="Search momo, sauce or drink"
                  className="h-12 w-full border border-black/20 bg-transparent pl-11 pr-4 text-sm font-semibold outline-none transition-colors placeholder:text-black/38 focus:border-[var(--menu-red)] focus:ring-4 focus:ring-red-100 dark:border-white/20 dark:placeholder:text-white/38"
                />
              </label>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="px-4 sm:px-0">
        {isLoading && <MenuSkeleton />}
        {isError && (
          <div className="my-8 border-l-4 border-[var(--menu-red)] bg-black/[0.035] p-6 text-center dark:bg-white/[0.05]">
            <p className="text-sm font-semibold">The menu could not be loaded.</p>
            <button onClick={() => refetch()} className="mt-3 text-sm font-black text-[var(--menu-red)] underline underline-offset-4">
              Try again
            </button>
          </div>
        )}

        {filtered.map((section) => (
          <div
            key={section.id}
            id={`menu-section-${section.id}`}
            role="region"
            aria-labelledby={`menu-section-title-${section.id}`}
            className="scroll-mt-[150px] py-7 sm:scroll-mt-[165px] sm:py-10"
          >
            <div className="mb-5 flex items-end justify-between gap-4 border-b-2 border-[var(--menu-ink)] pb-3 sm:mb-7">
              <div className="flex items-center gap-3">
                <span className="h-9 w-1.5 bg-[var(--menu-red)]" />
                <div>
                  <p className="text-[9px] font-black uppercase tracking-[0.2em] text-[var(--menu-red)]">
                    {section.isPopular ? "House picks" : "Menu section"}
                  </p>
                  <h2 id={`menu-section-title-${section.id}`} className="font-street text-[clamp(1.45rem,6vw,2.35rem)] leading-none">
                    {section.isPopular ? "Popular right now" : section.name}
                  </h2>
                </div>
              </div>
              <span className="pb-0.5 text-xs font-black tabular-nums text-black/45 dark:text-white/45">
                {String(section.items.length).padStart(2, "0")}
              </span>
            </div>
            <div className="grid border-t border-black/12 lg:grid-cols-2 lg:gap-x-8 lg:border-t-0">
              {section.items.map((item, itemIndex) => (
                <ItemRow
                  key={item.id}
                  item={item}
                  index={itemIndex}
                  onCustomize={() => setSheetItem(item)}
                />
              ))}
            </div>
          </div>
        ))}

        {!isLoading && !isError && filtered.length === 0 && (
          <div className="py-20 text-center">
            <SlidersHorizontal className="mx-auto h-8 w-8 text-[var(--menu-red)]" />
            <p className="font-street mt-4 text-xl">No dishes found</p>
            <p className="mt-2 text-sm text-black/50 dark:text-white/50">Try a shorter search or another flavour.</p>
          </div>
        )}
      </div>

      <ItemSheet item={sheetItem} open={!!sheetItem} onClose={() => setSheetItem(null)} />
    </section>
  );
}

function ItemRow({ item, index, onCustomize }: { item: MenuItem; index: number; onCustomize: () => void }) {
  const add = useCartStore((state) => state.add);
  const setQuantity = useCartStore((state) => state.setQuantity);
  const keyOf = useCartStore((state) => state.keyOf);
  const lines = useCartStore((state) => state.lines);
  const hasAddons = (item.addons?.length ?? 0) > 0;
  const itemLines = lines.filter((line) => line.itemId === item.id);
  const itemCount = itemLines.reduce((total, line) => total + line.quantity, 0);
  const plainLine = itemLines.find((line) => line.addons.length === 0);

  function addItem() {
    if (hasAddons) {
      onCustomize();
      return;
    }
    add(item, [], 1);
    toast.success(`${item.name} added`);
  }

  function decrease(line: CartLine) {
    setQuantity(keyOf(line), line.quantity - 1);
  }

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 4) * 0.035 }}
      className="group grid min-h-[142px] grid-cols-[104px_minmax(0,1fr)_auto] gap-3 border-b border-black/15 py-4 sm:min-h-[164px] sm:grid-cols-[136px_minmax(0,1fr)_auto] sm:gap-5 sm:py-5 dark:border-white/15"
    >
      <div className="relative h-[110px] self-center overflow-hidden bg-[var(--menu-tan)] sm:h-[132px]">
        <FoodImage
          src={item.imageUrl}
          alt={item.name}
          className="h-full w-full rounded-none transition-transform duration-500 group-hover:scale-[1.035]"
          sizes="(max-width: 640px) 104px, 136px"
          loading={index === 0 ? "eager" : "lazy"}
        />
        <FavoriteButton menuItemId={item.id} itemName={item.name} className="!absolute !left-1.5 !top-1.5 !h-8 !w-8 !rounded-[4px]" />
      </div>

      <div className="flex min-w-0 flex-col py-0.5">
        <h3 className="text-[15px] font-black leading-[1.15] sm:text-lg">{item.name}</h3>
        {item.description && (
          <p className="mt-1.5 line-clamp-2 text-[12px] leading-[1.5] text-black/52 sm:mt-2 sm:text-[13px] dark:text-white/52">
            {item.description}
          </p>
        )}
        <div className="mt-auto flex flex-wrap items-center gap-2 pt-2">
          {hasAddons && (
            <span className="text-[9px] font-black uppercase tracking-[0.12em] text-[var(--menu-red)]">Customise</span>
          )}
          {itemCount > 0 && (
            <motion.span key={itemCount} initial={{ scale: 0.75 }} animate={{ scale: 1 }} className="text-[10px] font-black text-black/45 dark:text-white/45">
              {itemCount} in cart
            </motion.span>
          )}
        </div>
      </div>

      <div className="flex min-w-[54px] flex-col items-end justify-between py-0.5 sm:min-w-[68px]">
        <span className="text-[15px] font-black tabular-nums sm:text-lg">{formatTk(item.price)}</span>
        {!hasAddons && plainLine ? (
          <div className="flex items-center border border-[var(--menu-red)]">
            <motion.button whileTap={{ scale: 0.88 }} type="button" onClick={() => decrease(plainLine)} aria-label={`Remove one ${item.name}`} className="grid h-9 w-8 place-items-center bg-[var(--menu-red)] text-white">
              <Minus className="h-4 w-4" />
            </motion.button>
            <span className="grid h-9 min-w-8 place-items-center text-xs font-black tabular-nums">{plainLine.quantity}</span>
            <motion.button whileTap={{ scale: 0.88 }} type="button" onClick={addItem} aria-label={`Add another ${item.name}`} className="grid h-9 w-8 place-items-center bg-[var(--menu-red)] text-white">
              <Plus className="h-4 w-4" />
            </motion.button>
          </div>
        ) : (
          <motion.button
            whileTap={{ scale: 0.86 }}
            type="button"
            onClick={addItem}
            aria-label={hasAddons ? `Customise ${item.name}` : `Add ${item.name} to cart`}
            className="grid h-11 w-11 place-items-center bg-[var(--menu-red)] text-white shadow-[4px_4px_0_var(--menu-ink)] transition-transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200"
          >
            <Plus className="h-5 w-5" strokeWidth={2.8} />
          </motion.button>
        )}
      </div>
    </motion.article>
  );
}

function MenuSkeleton() {
  return (
    <div className="grid gap-x-8 py-8 lg:grid-cols-2">
      {Array.from({ length: 6 }).map((_, index) => (
        <div key={index} className="grid h-40 animate-pulse grid-cols-[112px_1fr] gap-4 border-b border-black/10 py-4">
          <span className="bg-black/[0.06] dark:bg-white/[0.06]" />
          <span className="my-3 bg-black/[0.04] dark:bg-white/[0.04]" />
        </div>
      ))}
    </div>
  );
}
