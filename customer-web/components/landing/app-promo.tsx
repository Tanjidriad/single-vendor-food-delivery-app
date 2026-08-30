"use client";

import Link from "next/link";
import { ArrowRight, Bike, MapPin, ShoppingBag } from "lucide-react";

export function FulfillmentOptions() {
  return (
    <section className="mx-auto max-w-[1440px] px-4 pb-6 pt-20 sm:px-6 sm:pb-8 sm:pt-28 lg:px-10">
      <div className="relative overflow-hidden border-y-4 border-[var(--menu-ink)] bg-[var(--menu-red)] px-6 py-12 text-white sm:px-10 sm:py-16 lg:px-16 lg:py-20">
        <div className="pointer-events-none absolute -right-24 -top-28 h-80 w-80 rounded-full border-[42px] border-white/10" />
        <div className="pointer-events-none absolute -bottom-28 -left-24 h-72 w-72 rounded-full border-[36px] border-white/10" />

        <div className="relative flex flex-col items-start gap-8 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-white/60">
              Ready when you are
            </p>
            <h2 className="font-street mt-3 max-w-[16ch] text-[clamp(2.8rem,8vw,5.5rem)] leading-[0.84]">
              Your next box starts here.
            </h2>
            <p className="mt-4 max-w-[42ch] text-sm leading-6 text-white/75 sm:text-[15px]">
              See every available dish, build your basket, and choose delivery or
              pickup at checkout.
            </p>

            <div className="mt-6 flex flex-wrap gap-x-5 gap-y-2 text-xs font-semibold text-white/80">
              <span className="inline-flex items-center gap-2">
                <Bike className="h-4 w-4" /> Delivery
              </span>
              <span className="inline-flex items-center gap-2">
                <ShoppingBag className="h-4 w-4" /> Pickup
              </span>
              <span className="inline-flex items-center gap-2">
                <MapPin className="h-4 w-4" /> Order tracking
              </span>
            </div>
          </div>

          <Link
            href="/menu"
            className="group inline-flex h-14 flex-none items-center gap-3 border-2 border-white bg-white px-7 text-xs font-black uppercase tracking-[0.08em] text-[var(--menu-red)] transition-colors hover:bg-[var(--menu-ink)] hover:text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-white/40"
          >
            Browse the full menu
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
          </Link>
        </div>
      </div>
    </section>
  );
}
