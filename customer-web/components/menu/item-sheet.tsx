"use client";

import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Minus, Plus, X } from "lucide-react";
import { toast } from "sonner";

import { FoodImage } from "@/components/food-image";
import { FavoriteButton } from "@/components/menu/favorite-button";
import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";
import type { MenuAddon, MenuItem } from "@/types";

export function ItemSheet({ item, open, onClose }: { item: MenuItem | null; open: boolean; onClose: () => void }) {
  const add = useCartStore((state) => state.add);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [quantity, setQuantity] = useState(1);

  useEffect(() => {
    if (open && item) {
      setSelected({});
      setQuantity(1);
    }
  }, [open, item]);

  useEffect(() => {
    if (!open) return;
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handleKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", handleKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  const addons = useMemo(() => item?.addons ?? [], [item?.addons]);
  const chosen = useMemo(() => addons.filter((addon) => selected[addon.id]), [addons, selected]);
  const unitPrice = (item?.price ?? 0) + chosen.reduce((total, addon) => total + addon.price, 0);
  const total = unitPrice * quantity;

  function toggle(addon: MenuAddon) {
    setSelected((current) => ({ ...current, [addon.id]: !current[addon.id] }));
  }

  function confirm() {
    if (!item) return;
    add(item, chosen, quantity);
    toast.success(`${item.name} added`);
    onClose();
  }

  return (
    <AnimatePresence>
      {open && item && (
        <motion.div
          className="fixed inset-0 z-[var(--z-modal)] flex items-end justify-center sm:items-center sm:p-5"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.button aria-label="Close item details" className="absolute inset-0 bg-black/60 backdrop-blur-[2px]" onClick={onClose} />
          <motion.section
            role="dialog"
            aria-modal="true"
            aria-labelledby="item-sheet-title"
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            transition={{ type: "spring", stiffness: 360, damping: 34 }}
            className="wasabi-clipped-corner relative z-10 flex max-h-[92dvh] w-full max-w-[560px] flex-col overflow-hidden bg-[var(--menu-rice)] text-[var(--menu-ink)] shadow-[0_-18px_60px_rgba(0,0,0,0.3)]"
          >
            <div className="relative aspect-[16/9] w-full flex-none border-b-4 border-[var(--menu-ink)]">
              <FoodImage src={item.imageUrl} alt={item.name} className="h-full w-full rounded-none" sizes="(max-width: 640px) 100vw, 560px" loading="eager" />
              <div className="absolute right-3 top-3 flex gap-2">
                <FavoriteButton menuItemId={item.id} itemName={item.name} className="!rounded-[4px]" />
                <button onClick={onClose} aria-label="Close" className="grid h-10 w-10 place-items-center bg-[var(--menu-ink)] text-[var(--menu-rice)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200">
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto px-5 pb-5 pt-6 sm:px-7">
              <p className="text-[9px] font-black uppercase tracking-[0.2em] text-[var(--menu-red)]">Made to order</p>
              <div className="mt-1 flex items-start justify-between gap-4">
                <h2 id="item-sheet-title" className="font-street text-[1.8rem] leading-[0.95] sm:text-[2.2rem]">{item.name}</h2>
                <p className="flex-none text-lg font-black tabular-nums">{formatTk(item.price)}</p>
              </div>
              {item.description && <p className="mt-3 max-w-[46ch] text-sm leading-6 text-black/55 dark:text-white/55">{item.description}</p>}

              {addons.length > 0 && (
                <div className="mt-7 border-t-2 border-[var(--menu-ink)] pt-4">
                  <div className="flex items-center justify-between gap-3">
                    <h3 className="text-xs font-black uppercase tracking-[0.12em]">Make it yours</h3>
                    <span className="text-[10px] font-bold text-black/40 dark:text-white/40">Optional</span>
                  </div>
                  <ul className="mt-2 divide-y divide-black/12 dark:divide-white/12">
                    {addons.map((addon) => {
                      const active = !!selected[addon.id];
                      return (
                        <li key={addon.id}>
                          <button type="button" onClick={() => toggle(addon)} className="flex w-full items-center gap-3 py-3.5 text-left focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-inset focus-visible:ring-red-200">
                            <span className={`grid h-5 w-5 flex-none place-items-center border-2 ${active ? "border-[var(--menu-red)] bg-[var(--menu-red)] text-white" : "border-black/30 dark:border-white/30"}`}>
                              {active && <Plus className="h-3.5 w-3.5" strokeWidth={3} />}
                            </span>
                            <span className="flex-1 text-sm font-bold">{addon.name}</span>
                            <span className="text-sm font-black tabular-nums">+{formatTk(addon.price)}</span>
                          </button>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}
            </div>

            <div className="grid flex-none grid-cols-[auto_minmax(0,1fr)] border-t-4 border-[var(--menu-ink)] bg-[var(--menu-ink)] text-white">
              <div className="flex items-center border-r border-white/25">
                <motion.button whileTap={{ scale: 0.86 }} aria-label="Decrease quantity" onClick={() => setQuantity((current) => Math.max(1, current - 1))} className="grid h-16 w-12 place-items-center sm:w-14">
                  <Minus className="h-4 w-4" />
                </motion.button>
                <motion.span key={quantity} initial={{ scale: 0.7 }} animate={{ scale: 1 }} className="w-7 text-center text-sm font-black tabular-nums">{quantity}</motion.span>
                <motion.button whileTap={{ scale: 0.86 }} aria-label="Increase quantity" onClick={() => setQuantity((current) => current + 1)} className="grid h-16 w-12 place-items-center sm:w-14">
                  <Plus className="h-4 w-4" />
                </motion.button>
              </div>
              <motion.button whileTap={{ scale: 0.985 }} onClick={confirm} className="flex h-16 min-w-0 items-center justify-between gap-3 bg-[var(--menu-red)] px-5 text-left focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-inset focus-visible:ring-red-200 sm:px-7">
                <span className="text-sm font-black uppercase tracking-[0.06em]">Add to cart</span>
                <span className="text-sm font-black tabular-nums">{formatTk(total)}</span>
              </motion.button>
            </div>
          </motion.section>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
