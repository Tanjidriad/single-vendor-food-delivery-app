"use client";

import { MapPin, ShoppingBag } from "lucide-react";

import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";

/** Thin top utility bar: first-order promo · delivery area · live cart total.
    Cloned from the Figma "Order.UK" top bar, re-skinned to Wasabi. */
export function UtilityBar() {
  const count = useCartStore((s) => s.lines.reduce((a, l) => a + l.quantity, 0));
  const subtotal = useCartStore((s) =>
    s.lines.reduce(
      (a, l) =>
        a + (l.price + l.addons.reduce((x, ad) => x + ad.price, 0)) * l.quantity,
      0
    )
  );

  return (
    <div className="w-full bg-[var(--surface-sunken)] text-[13px]">
      <div className="mx-auto flex max-w-[1440px] items-center justify-between gap-3 px-4 py-2 sm:px-6 lg:px-10">
        <p className="hidden sm:block text-[var(--foreground-dim)]">
          🥟 Get <b className="text-[var(--foreground)]">10% off</b> your first order —{" "}
          <span className="font-semibold text-[var(--brand)]">Promo: WASABI10</span>
        </p>
        <button className="flex items-center gap-1.5 text-[var(--foreground-dim)] transition-colors hover:text-[var(--foreground)]">
          <MapPin className="h-3.5 w-3.5 text-[var(--brand)]" />
          <span className="max-w-[46vw] truncate sm:max-w-none">
            Deliver to <b className="text-[var(--foreground)]">Dhaka</b>
          </span>
          <span className="font-semibold text-[var(--brand)]">· Change</span>
        </button>
        <div className="flex items-center gap-2 rounded-full bg-[var(--ink)] px-3 py-1.5 text-[var(--on-ink)]">
          <ShoppingBag className="h-3.5 w-3.5" />
          <span className="font-semibold">{count}</span>
          <span className="opacity-50">·</span>
          <span className="font-semibold tabular-nums">{formatTk(subtotal)}</span>
        </div>
      </div>
    </div>
  );
}
