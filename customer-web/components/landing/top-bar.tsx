import { Bike, ShoppingBag, Radio } from "lucide-react";

/** Thin promo/utility strip above the header (truthful capabilities only). */
export function TopBar() {
  return (
    <div className="w-full bg-[var(--brand)] text-white">
      <div className="mx-auto flex h-9 max-w-[1440px] items-center justify-center gap-5 px-4 text-[11px] font-semibold sm:h-10 sm:justify-between sm:px-6 sm:text-xs lg:px-10">
        <span className="inline-flex items-center gap-1.5">
          <Bike className="h-3.5 w-3.5" />
          Delivery
          <span className="mx-1 opacity-40">/</span>
          <ShoppingBag className="h-3.5 w-3.5" />
          Pickup
        </span>
        <span className="hidden items-center gap-1.5 sm:inline-flex">
          <Radio className="h-3.5 w-3.5" />
          Live order tracking on every order
        </span>
      </div>
    </div>
  );
}
