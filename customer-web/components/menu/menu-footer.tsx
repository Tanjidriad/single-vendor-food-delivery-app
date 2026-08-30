"use client";

import Link from "next/link";
import { ArrowUpRight } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { useRestaurant } from "@/lib/api/queries/menu";
import { RESTAURANT_INFO } from "@/lib/restaurant-info";

const links = [
  { href: "/", label: "Home" },
  { href: "/offers", label: "Offers" },
  { href: "/orders", label: "Orders" },
  { href: "/account", label: "Account" },
];

export function MenuFooter() {
  const { data: restaurant } = useRestaurant();
  const name = restaurant?.name ?? RESTAURANT_INFO.name;

  return (
    <footer className="relative overflow-hidden border-t-4 border-[var(--menu-ink)] bg-[var(--menu-red)] text-white">
      <div
        className="pointer-events-none absolute -right-16 top-16 h-56 w-56 rounded-full bg-[#f4dfb8] sm:right-[7%] sm:top-10 sm:h-72 sm:w-72 lg:h-96 lg:w-96"
        aria-hidden="true"
      />
      <ToriiMark className="pointer-events-none absolute -right-7 top-24 h-40 w-48 text-[var(--menu-ink)] sm:right-[9%] sm:top-20 sm:h-52 sm:w-64 lg:top-16 lg:h-72 lg:w-80" />

      <div className="relative mx-auto max-w-[1440px] px-5 pb-8 pt-12 sm:px-8 sm:pb-10 sm:pt-16 lg:px-10 lg:pt-20">
        <div className="max-w-[820px]">
          <p className="flex items-center gap-3 text-[10px] font-black uppercase tracking-[0.22em] text-white/70">
            <span className="h-px w-8 bg-white/65" /> From steamer to street
          </p>
          <h2 className="font-street mt-5 text-[clamp(3.7rem,13.5vw,11rem)] leading-[0.72] tracking-[-0.075em]">
            FOLDED
            <br />
            TODAY.
          </h2>
          <p className="font-street mt-7 text-xl uppercase leading-none sm:text-3xl">Gone tonight.</p>
          <a
            href="#menu-list"
            className="mt-8 inline-flex min-h-12 items-center gap-5 border-2 border-white bg-white px-5 text-xs font-black uppercase tracking-[0.12em] text-[var(--menu-red)] transition-colors hover:bg-[var(--menu-ink)] hover:text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-white/50"
          >
            Back to the menu <ArrowUpRight className="h-4 w-4" />
          </a>
        </div>

        <div className="mt-14 border-t-2 border-white/70 pt-5 sm:mt-20 lg:mt-24">
          <div className="grid gap-8 md:grid-cols-[1fr_auto] md:items-end">
            <div>
              <div className="flex items-center gap-3">
                <span className="grid h-11 w-11 place-items-center bg-[var(--menu-ink)] text-white">
                  <ToriiMark className="h-5 w-7" />
                </span>
                <div>
                  <span className="block text-[10px] font-black tracking-[0.2em] text-white/65">芥末</span>
                  <span className="font-street block text-2xl uppercase leading-none">WASABI</span>
                </div>
              </div>
              <p className="mt-4 max-w-sm text-[11px] font-semibold leading-5 text-white/65">
                {name} · Hand-folded momo for delivery and counter pickup.
              </p>
            </div>

            <nav
              aria-label="Footer"
              className="grid grid-cols-2 gap-x-8 gap-y-3 border-t border-white/35 pt-5 sm:flex sm:flex-wrap sm:border-0 sm:pt-0"
            >
              {links.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className="group flex items-center justify-between gap-3 text-[11px] font-black uppercase tracking-[0.1em] text-white/70 transition-colors hover:text-white"
                >
                  {link.label}
                  <span className="h-1.5 w-1.5 bg-white/45 transition-transform group-hover:rotate-45 group-hover:bg-white" />
                </Link>
              ))}
            </nav>
          </div>
        </div>
      </div>

      <div className="relative border-t border-black/25 bg-[var(--menu-ink)] px-5 py-4 text-[9px] font-bold uppercase tracking-[0.14em] text-white/40 sm:px-8 lg:px-10">
        <div className="mx-auto flex max-w-[1360px] flex-wrap items-center justify-between gap-2">
          <span>© {new Date().getFullYear()} {name}</span>
          <span>Steam · Sauce · Repeat</span>
        </div>
      </div>
    </footer>
  );
}
