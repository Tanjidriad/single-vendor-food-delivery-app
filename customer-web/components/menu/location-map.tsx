"use client";

import { MapPin, Phone } from "lucide-react";

import { useRestaurant } from "@/lib/api/queries/menu";
import { RESTAURANT_INFO } from "@/lib/restaurant-info";

export function LocationMap() {
  const { data: restaurant } = useRestaurant();

  const hasLocation =
    !!restaurant?.latitude &&
    !!restaurant?.longitude &&
    restaurant.latitude !== 0 &&
    restaurant.longitude !== 0;
  const lat = restaurant?.latitude ?? 0;
  const lng = restaurant?.longitude ?? 0;
  const name = restaurant?.name ?? RESTAURANT_INFO.name;
  const phone = restaurant?.phone ?? RESTAURANT_INFO.phone;
  const address = [
    restaurant?.addressLine ?? RESTAURANT_INFO.addressLine,
    restaurant?.city ?? RESTAURANT_INFO.city,
    restaurant?.country ?? RESTAURANT_INFO.country,
  ]
    .filter(Boolean)
    .join(", ");

  const d = 0.012;
  const bbox = `${lng - d},${lat - d},${lng + d},${lat + d}`;

  return (
    <section className="mx-auto max-w-[1440px] px-4 pt-16 sm:px-6 lg:px-10">
      <div className="mb-6">
        <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[var(--brand)]">
          Find us
        </p>
        <h2 className="mt-2 font-display text-[clamp(1.6rem,3.5vw,2.4rem)] font-black tracking-[-0.03em]">
          Where the momo is made
        </h2>
      </div>

      <div className={`overflow-hidden rounded-[14px] border border-[var(--border-subtle)] bg-[var(--surface)] shadow-[0_10px_30px_rgba(24,22,21,0.08)] ${hasLocation ? "lg:grid lg:grid-cols-[1fr_1.4fr]" : ""}`}>
        {/* Address card */}
        <div className="flex flex-col justify-center gap-4 p-6 sm:p-8">
          <p className="font-display text-xl font-black">{name}</p>
          {address && (
            <p className="flex items-start gap-2.5 text-sm leading-6 text-[var(--foreground-dim)]">
              <MapPin className="mt-0.5 h-4 w-4 flex-none text-[var(--brand)]" />
              {address}
            </p>
          )}
          {phone && (
            <a
              href={`tel:${phone.replace(/\s/g, "")}`}
              className="inline-flex w-fit items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface)] px-4 py-2 text-sm font-semibold transition-colors hover:border-[var(--brand)] hover:text-[var(--brand)]"
            >
              <Phone className="h-4 w-4 text-[var(--brand)]" /> {phone}
            </a>
          )}
          <p className="text-xs leading-5 text-[var(--foreground-mute)]">
            Delivery availability and the route-based fee are confirmed for your address at checkout.
          </p>
        </div>

        {/* Map */}
        {hasLocation && <div className="relative min-h-[260px] border-t border-[var(--border-subtle)] lg:min-h-[340px] lg:border-l lg:border-t-0">
          <iframe
            title={`${name} location`}
            className="h-full min-h-[260px] w-full grayscale-[0.15] lg:min-h-[340px]"
            loading="lazy"
            src={`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lng}`}
          />
        </div>}
      </div>
    </section>
  );
}
