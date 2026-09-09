"use client";

import { useState } from "react";
import { Bike, Clock3, MapPin, ShoppingBag } from "lucide-react";

import { useRestaurant } from "@/lib/api/queries/menu";
import { cn } from "@/lib/utils";

type Fulfilment = "DELIVERY" | "PICKUP";

/**
 * Utility strip above the header.
 *
 * PRESENTATIONAL ONLY — the Delivery/Pickup control and the "deliver to" chip
 * are the agreed visual shell. There is no global fulfilment or selected-address
 * state in the app yet (orderType lives on the order and in checkout), so
 * switching here changes nothing downstream. Wire both to a real store before
 * telling a customer this control does anything.
 */
export function TopBar() {
  const { data: restaurant } = useRestaurant();
  const [fulfilment, setFulfilment] = useState<Fulfilment>("DELIVERY");

  const area = restaurant?.city ?? restaurant?.addressLine ?? null;
  const prepMinutes = restaurant?.settings?.defaultPrepMinutes;

  return (
    <div className="w-full bg-[var(--menu-red)] text-white">
      <div className="mx-auto flex h-10 max-w-[1440px] items-center gap-4 px-4 sm:px-6 lg:px-10">
        <div className="flex flex-none border border-white/45" role="group" aria-label="Fulfilment">
          {(["DELIVERY", "PICKUP"] as const).map((mode) => (
            <button
              key={mode}
              type="button"
              aria-pressed={fulfilment === mode}
              onClick={() => setFulfilment(mode)}
              className={cn(
                "flex items-center gap-1.5 px-3 py-1 text-[9px] font-black uppercase tracking-[0.14em] transition-colors",
                fulfilment === mode
                  ? "bg-white text-[var(--menu-red)]"
                  : "text-white/75 hover:text-white"
              )}
            >
              {mode === "DELIVERY" ? <Bike className="h-3 w-3" /> : <ShoppingBag className="h-3 w-3" />}
              {mode === "DELIVERY" ? "Delivery" : "Pickup"}
            </button>
          ))}
        </div>

        {area && (
          <span className="hidden items-center gap-1.5 whitespace-nowrap text-xs text-white/85 md:inline-flex">
            <MapPin className="h-3.5 w-3.5" />
            {fulfilment === "DELIVERY" ? "Deliver to" : "Collect from"}
            <span className="font-bold underline decoration-white/50 decoration-dashed underline-offset-4">{area}</span>
          </span>
        )}

        {typeof prepMinutes === "number" && prepMinutes > 0 && (
          <span className="ml-auto inline-flex items-center gap-1.5 whitespace-nowrap text-[9px] font-black uppercase tracking-[0.14em] text-white/90">
            <Clock3 className="h-3.5 w-3.5" />
            Next slot · {prepMinutes} min
          </span>
        )}
      </div>
    </div>
  );
}
