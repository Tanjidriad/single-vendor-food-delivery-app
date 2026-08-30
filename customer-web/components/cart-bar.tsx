"use client";

import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { ArrowRight, ShoppingBag } from "lucide-react";

import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";

export function CartBar() {
  const count = useCartStore((state) => state.lines.reduce((total, line) => total + line.quantity, 0));
  const subtotal = useCartStore((state) =>
    state.lines.reduce(
      (total, line) => total + (line.price + line.addons.reduce((sum, addon) => sum + addon.price, 0)) * line.quantity,
      0
    )
  );

  return (
    <AnimatePresence>
      {count > 0 && (
        <motion.div
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          transition={{ type: "spring", stiffness: 390, damping: 34 }}
          className="cart-bar-offset fixed inset-x-0 z-[calc(var(--z-drawer)+1)] px-3 sm:bottom-5 sm:px-5"
        >
          <motion.div whileTap={{ scale: 0.99 }} className="mx-auto max-w-[620px]">
            <Link
              href="/checkout"
              className="wasabi-ticket grid h-16 grid-cols-[auto_minmax(0,1fr)_56px] items-center overflow-hidden bg-[var(--menu-ink)] pl-6 text-[var(--menu-rice)] shadow-[0_18px_46px_rgba(0,0,0,0.28)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200 sm:h-[68px]"
            >
              <span className="flex items-center gap-3 border-r border-white/25 pr-4">
                <span className="relative">
                  <ShoppingBag className="h-5 w-5" />
                  <motion.span key={count} initial={{ scale: 0.4 }} animate={{ scale: [1.3, 1] }} className="absolute -right-2.5 -top-2.5 h-3 w-3 rounded-full bg-[var(--menu-red)]" />
                </span>
                <span className="whitespace-nowrap text-sm font-black">{count} {count === 1 ? "item" : "items"}</span>
              </span>
              <span className="flex min-w-0 items-center justify-center gap-1.5 px-3 text-xs font-black uppercase tracking-[0.06em] sm:text-sm">
                <span>View cart</span>
                <span className="text-white/35">·</span>
                <motion.span key={subtotal} initial={{ opacity: 0.4, y: 3 }} animate={{ opacity: 1, y: 0 }} className="truncate tabular-nums">{formatTk(subtotal)}</motion.span>
              </span>
              <span className="grid h-full place-items-center bg-[var(--menu-red)] text-white">
                <ArrowRight className="h-5 w-5" />
              </span>
            </Link>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
