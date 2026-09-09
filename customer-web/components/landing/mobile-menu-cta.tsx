"use client";

import Link from "next/link";
import { ArrowRight, ShoppingBag } from "lucide-react";

import { useCartStore } from "@/store/cart-store";

export function MobileMenuCta() {
  const count = useCartStore((state) =>
    state.lines.reduce((total, line) => total + line.quantity, 0)
  );

  return (
    <div className="fixed inset-x-0 bottom-0 z-[var(--z-drawer)] border-t border-[var(--border-subtle)] bg-[color-mix(in_srgb,var(--background)_94%,transparent)] px-4 pb-[calc(0.75rem+env(safe-area-inset-bottom))] pt-3 backdrop-blur-xl sm:hidden">
      <Link
        href="/menu"
        className="mx-auto flex h-14 max-w-md items-center justify-between rounded-full bg-[var(--brand)] px-5 text-white shadow-[0_14px_34px_rgba(210,31,60,0.28)] transition-transform active:scale-[0.985] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_25%,transparent)]"
      >
        <span className="flex items-center gap-2.5 text-sm font-bold">
          <span className="grid h-8 w-8 place-items-center rounded-full bg-white/15">
            <ShoppingBag className="h-4 w-4" />
          </span>
          {count > 0
            ? `Continue with ${count} ${count === 1 ? "item" : "items"}`
            : "Browse the menu"}
        </span>
        <ArrowRight className="h-4 w-4" />
      </Link>
    </div>
  );
}
