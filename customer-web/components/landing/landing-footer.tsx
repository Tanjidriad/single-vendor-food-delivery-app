"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowUpRight, ChevronDown, Clock3, Mail, MapPin, Phone } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { useRestaurant } from "@/lib/api/queries/menu";
import { groupedHours } from "@/lib/restaurant-info";

const links = [
  { href: "/menu", label: "Menu" },
  { href: "/offers", label: "Offers" },
  { href: "/orders", label: "Orders" },
  { href: "/support", label: "Support" },
];

export function LandingFooter() {
  const { data: restaurant } = useRestaurant();
  const hours = groupedHours(restaurant?.operatingHours ?? []);
  const address = [restaurant?.addressLine, restaurant?.city, restaurant?.country]
    .filter(Boolean)
    .join(", ");

  // Resolved after mount: the server has no way to know the visitor's weekday,
  // and rendering one on the server would hydrate into a mismatch.
  const [today, setToday] = useState<number | null>(null);
  useEffect(() => setToday(new Date().getDay()), []);
  const todayRow = today === null ? null : hours.find((row) => row.days.includes(today));

  const hourRows = hours.map((row) => (
    <li key={row.label} className="flex justify-between gap-4 border-b border-white/10 pb-2">
      <span className="text-white/85">{row.label}</span>
      <span className="tabular-nums">{row.value}</span>
    </li>
  ));

  const contactRows = (
    <>
      {restaurant?.phone && (
        <li>
          <a href={`tel:${restaurant.phone.replace(/\s/g, "")}`} className="flex items-center gap-2 hover:text-white">
            <Phone className="h-3.5 w-3.5 text-[var(--menu-red)]" />
            {restaurant.phone}
          </a>
        </li>
      )}
      {restaurant?.email && (
        <li>
          <a href={`mailto:${restaurant.email}`} className="flex items-center gap-2 hover:text-white">
            <Mail className="h-3.5 w-3.5 text-[var(--menu-red)]" />
            {restaurant.email}
          </a>
        </li>
      )}
      {address && (
        <li className="flex items-start gap-2">
          <MapPin className="mt-0.5 h-3.5 w-3.5 flex-none text-[var(--menu-red)]" />
          <span>{address}</span>
        </li>
      )}
    </>
  );

  return (
    <footer className="mt-12 border-t-4 border-[var(--menu-red)] bg-[var(--menu-bar)] text-white sm:mt-20 lg:mt-24">
      <div className="mx-auto max-w-[1440px] px-5 pb-7 pt-8 sm:px-8 sm:py-12 lg:px-10 lg:py-16">
        <div className="grid gap-7 lg:grid-cols-[1.2fr_0.8fr_1fr] lg:gap-10">
          <div>
            <p className="text-[9px] font-black uppercase tracking-[0.22em] text-[var(--menu-red)]">Your next box</p>
            <h2 className="font-street mt-3 text-[clamp(2.1rem,7vw,6.4rem)] leading-[0.82]">STEAM.<br />SAUCE.<br />REPEAT.</h2>
            <Link href="/menu" className="mt-6 inline-flex min-h-11 items-center gap-4 bg-[var(--menu-red)] px-5 text-[11px] font-black uppercase tracking-[0.1em] transition-colors hover:bg-white hover:text-[var(--menu-bar)] sm:mt-7">
              Build an order <ArrowUpRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="border-t border-white/15 pt-5 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
            {/* The header already carries the lockup; on a phone it is dead height. */}
            <div className="mb-6 hidden items-center gap-3 lg:flex">
              <span className="grid h-10 w-10 place-items-center bg-[var(--menu-red)]"><ToriiMark className="h-5 w-6" /></span>
              <div><span className="block text-[8px] font-black tracking-[0.2em] text-white/40">芥末</span><span className="font-street block text-xl leading-none">WASABI</span></div>
            </div>
            <nav aria-label="Footer" className="grid grid-cols-4 gap-x-4 gap-y-3 lg:grid-cols-2 lg:gap-x-6">
              {links.map((link) => <Link key={link.href} href={link.href} className="text-[11px] font-black uppercase tracking-[0.08em] text-white/55 hover:text-white">{link.label}</Link>)}
            </nav>
            <div className="mt-5 flex gap-4 text-[10px] font-bold uppercase tracking-[0.08em] text-white/35 sm:mt-7">
              <Link href="/privacy" className="hover:text-white">Privacy</Link>
              <Link href="/terms" className="hover:text-white">Terms</Link>
            </div>
          </div>

          <div className="border-t border-white/15 pt-5 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
            <p className="mb-4 flex items-center gap-2 text-[9px] font-black uppercase tracking-[0.18em] text-white/35">
              <Clock3 className="h-3.5 w-3.5 text-[var(--menu-red)]" /> Counter details
            </p>

            {/* A full week of rows is most of a phone screen, so collapse to today
                and keep the rest one tap away. When every day keeps the same
                hours groupedHours already returns a single row — a disclosure
                that reveals only what the summary showed would be noise. */}
            {hours.length > 1 && (
              <details className="group mb-4 lg:hidden">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-3 border-b border-white/10 pb-2 text-xs font-semibold text-white/55 [&::-webkit-details-marker]:hidden">
                  <span className="flex items-center gap-2">
                    <span className="text-white/85">{todayRow ? todayRow.label : "Opening hours"}</span>
                    {todayRow && <span className="tabular-nums">{todayRow.value}</span>}
                  </span>
                  <ChevronDown className="h-4 w-4 flex-none text-white/40 transition-transform group-open:rotate-180" />
                </summary>
                <ul className="mt-3 space-y-3 text-xs font-semibold text-white/55">{hourRows}</ul>
              </details>
            )}

            <ul
              className={
                hours.length > 1
                  ? "hidden space-y-3 text-xs font-semibold text-white/55 lg:block"
                  : "space-y-3 text-xs font-semibold text-white/55"
              }
            >
              {hourRows}
            </ul>

            <ul className="space-y-3 text-xs font-semibold text-white/55 lg:mt-3">{contactRows}</ul>
          </div>
        </div>
      </div>
      <div className="border-t border-white/10 px-5 pb-[calc(4.75rem+env(safe-area-inset-bottom))] pt-4 text-[9px] font-bold uppercase tracking-[0.12em] text-white/30 sm:px-8 sm:pb-4 lg:px-10">
        <div className="mx-auto flex max-w-[1360px] justify-between gap-4"><span>© {new Date().getFullYear()} Wasabi Momo House</span><span>Dhaka · Bangladesh</span></div>
      </div>
    </footer>
  );
}
