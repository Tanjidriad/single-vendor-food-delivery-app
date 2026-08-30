"use client";

import Link from "next/link";
import { MapPin, ShoppingBag, UserRound } from "lucide-react";
import { motion } from "framer-motion";

import { ToriiMark } from "@/components/brand";
import { useAddresses } from "@/lib/api/queries/addresses";
import { useAuth } from "@/lib/auth/use-auth";
import { useCartStore } from "@/store/cart-store";

export function MenuHeader() {
  const { isAuthenticated, hydrated } = useAuth();
  const { data: addresses } = useAddresses();
  const count = useCartStore((state) =>
    state.lines.reduce((total, line) => total + line.quantity, 0)
  );

  const defaultAddress =
    addresses?.find((address) => address.isDefault) ?? addresses?.[0];
  const locationLabel = defaultAddress
    ? [defaultAddress.line1, defaultAddress.city].filter(Boolean).join(", ")
    : hydrated && isAuthenticated
      ? "Choose delivery address"
      : "Set delivery location";
  const accountHref =
    hydrated && isAuthenticated ? "/account" : "/login?next=/account";

  return (
    <header className="sticky top-0 z-[var(--z-sticky)] border-b border-black/10 bg-[color-mix(in_srgb,var(--menu-rice)_95%,transparent)] backdrop-blur-xl">
      <div className="mx-auto flex h-[68px] max-w-[1440px] items-center gap-3 px-4 sm:h-[76px] sm:px-6 lg:px-10">
        <Link
          href="/"
          aria-label="WASABI home"
          className="flex flex-none items-center gap-2 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200"
        >
          <span className="relative grid h-9 w-9 place-items-center overflow-hidden rounded-full bg-[var(--menu-red)] text-white">
            <ToriiMark className="h-[21px] w-6" />
          </span>
          <span className="hidden sm:block">
            <span className="block text-[10px] font-black leading-none tracking-[0.18em] text-[var(--menu-red)]">
              芥末
            </span>
            <span className="font-street block text-xl leading-none">WASABI</span>
          </span>
        </Link>

        <span className="hidden h-8 w-px bg-black/12 sm:block" />

        <Link
          href={accountHref}
          className="flex min-w-0 flex-1 items-center gap-2 px-1 text-left focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200 sm:max-w-md"
        >
          <MapPin className="h-[18px] w-[18px] flex-none text-[var(--menu-red)]" />
          <span className="min-w-0">
            <span className="block text-[9px] font-black uppercase tracking-[0.16em] text-black/45 dark:text-white/45">
              Deliver to
            </span>
            <span className="block truncate text-[13px] font-bold sm:text-sm">
              {locationLabel}
            </span>
          </span>
        </Link>

        <nav className="hidden items-center gap-6 lg:flex" aria-label="Menu page">
          <Link href="/menu" className="text-sm font-black text-[var(--menu-red)]">
            Menu
          </Link>
          <Link href="/offers" className="text-sm font-bold text-black/55 transition-colors hover:text-black dark:text-white/55 dark:hover:text-white">
            Offers
          </Link>
          <Link href="/orders" className="text-sm font-bold text-black/55 transition-colors hover:text-black dark:text-white/55 dark:hover:text-white">
            Orders
          </Link>
        </nav>

        <Link
          href={accountHref}
          aria-label={hydrated && isAuthenticated ? "Open account" : "Sign in"}
          className="hidden h-10 w-10 flex-none place-items-center border border-black/15 text-black transition-colors hover:border-[var(--menu-red)] hover:text-[var(--menu-red)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200 sm:grid dark:border-white/15 dark:text-white"
        >
          <UserRound className="h-[18px] w-[18px]" />
        </Link>

        <motion.div whileTap={{ scale: 0.94 }} className="relative flex-none">
          <Link
            href={count > 0 ? "/checkout" : "/menu#menu-list"}
            aria-label={count > 0 ? `Open cart with ${count} items` : "Cart is empty"}
            className="grid h-11 w-11 place-items-center bg-[var(--menu-ink)] text-[var(--menu-rice)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200"
          >
            <ShoppingBag className="h-5 w-5" />
          </Link>
          {count > 0 && (
            <motion.span
              key={count}
              initial={{ scale: 0.4 }}
              animate={{ scale: [1.25, 1] }}
              className="absolute -right-1.5 -top-1.5 grid h-5 min-w-5 place-items-center rounded-full bg-[var(--menu-red)] px-1 text-[10px] font-black text-white ring-2 ring-[var(--menu-rice)]"
            >
              {count > 99 ? "99+" : count}
            </motion.span>
          )}
        </motion.div>
      </div>
    </header>
  );
}
