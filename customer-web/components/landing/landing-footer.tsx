"use client";

import Link from "next/link";
import { ArrowUpRight, Clock3, Mail, MapPin, Phone } from "lucide-react";

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

  return (
    <footer className="mt-16 border-t-4 border-[var(--menu-red)] bg-[var(--menu-ink)] text-white sm:mt-24">
      <div className="mx-auto max-w-[1440px] px-5 pb-8 pt-10 sm:px-8 sm:py-12 lg:px-10 lg:py-16">
        <div className="grid gap-10 lg:grid-cols-[1.2fr_0.8fr_1fr]">
          <div>
            <p className="text-[9px] font-black uppercase tracking-[0.22em] text-[var(--menu-red)]">Your next box</p>
            <h2 className="font-street mt-3 text-[clamp(2.7rem,7vw,6.4rem)] leading-[0.82]">STEAM.<br />SAUCE.<br />REPEAT.</h2>
            <Link href="/menu" className="mt-7 inline-flex min-h-11 items-center gap-4 bg-[var(--menu-red)] px-5 text-[11px] font-black uppercase tracking-[0.1em] transition-colors hover:bg-white hover:text-[var(--menu-ink)]">
              Build an order <ArrowUpRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="border-t border-white/15 pt-5 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
            <div className="mb-6 flex items-center gap-3">
              <span className="grid h-10 w-10 place-items-center bg-[var(--menu-red)]"><ToriiMark className="h-5 w-6" /></span>
              <div><span className="block text-[8px] font-black tracking-[0.2em] text-white/40">芥末</span><span className="font-street block text-xl leading-none">WASABI</span></div>
            </div>
            <nav aria-label="Footer" className="grid grid-cols-2 gap-x-6 gap-y-3">
              {links.map((link) => <Link key={link.href} href={link.href} className="text-[11px] font-black uppercase tracking-[0.08em] text-white/55 hover:text-white">{link.label}</Link>)}
            </nav>
            <div className="mt-7 flex gap-4 text-[10px] font-bold uppercase tracking-[0.08em] text-white/35">
              <Link href="/privacy" className="hover:text-white">Privacy</Link>
              <Link href="/terms" className="hover:text-white">Terms</Link>
            </div>
          </div>

          <div className="border-t border-white/15 pt-5 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
            <p className="mb-4 flex items-center gap-2 text-[9px] font-black uppercase tracking-[0.18em] text-white/35"><Clock3 className="h-3.5 w-3.5 text-[var(--menu-red)]" /> Counter details</p>
            <ul className="space-y-3 text-xs font-semibold text-white/55">
              {hours.map((row) => <li key={row.label} className="flex justify-between gap-4 border-b border-white/10 pb-2"><span className="text-white/85">{row.label}</span><span className="tabular-nums">{row.value}</span></li>)}
              {restaurant?.phone && <li><a href={`tel:${restaurant.phone.replace(/\s/g, "")}`} className="flex items-center gap-2 hover:text-white"><Phone className="h-3.5 w-3.5 text-[var(--menu-red)]" />{restaurant.phone}</a></li>}
              {restaurant?.email && <li><a href={`mailto:${restaurant.email}`} className="flex items-center gap-2 hover:text-white"><Mail className="h-3.5 w-3.5 text-[var(--menu-red)]" />{restaurant.email}</a></li>}
              {address && <li className="flex items-start gap-2"><MapPin className="mt-0.5 h-3.5 w-3.5 flex-none text-[var(--menu-red)]" /><span>{address}</span></li>}
            </ul>
          </div>
        </div>
      </div>
      <div className="border-t border-white/10 px-5 pb-[calc(4.75rem+env(safe-area-inset-bottom))] pt-4 text-[9px] font-bold uppercase tracking-[0.12em] text-white/30 sm:px-8 sm:pb-4 lg:px-10">
        <div className="mx-auto flex max-w-[1360px] justify-between gap-4"><span>© {new Date().getFullYear()} Wasabi Momo House</span><span>Dhaka · Bangladesh</span></div>
      </div>
    </footer>
  );
}
