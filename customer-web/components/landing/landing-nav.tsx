"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ShoppingBag, UserRound } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { ThemeToggle } from "@/components/theme-toggle";
import { NotificationBell } from "@/components/notifications/notification-bell";
import { useAuth } from "@/lib/auth/use-auth";
import { useCartStore } from "@/store/cart-store";
import { cn } from "@/lib/utils";

export function LandingNav() {
  const pathname = usePathname();
  const { isAuthenticated, hydrated } = useAuth();
  const count = useCartStore((state) =>
    state.lines.reduce((total, line) => total + line.quantity, 0)
  );
  const links = [
    { href: "/", label: "Home" },
    { href: "/menu", label: "Menu" },
    { href: "/offers", label: "Offers" },
    ...(hydrated && isAuthenticated ? [{ href: "/orders", label: "Orders" }] : []),
  ];

  return (
    <nav className="sticky top-0 z-[var(--z-sticky)] w-full border-b-4 border-[var(--menu-red)] bg-[var(--menu-ink)] text-white">
      <div className="mx-auto flex h-16 max-w-[1440px] items-center px-4 sm:h-[72px] sm:px-6 lg:px-10">
        <Link href="/" aria-label="Wasabi home" className="flex items-center gap-2.5 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200">
          <span className="grid h-9 w-9 place-items-center bg-[var(--menu-red)] sm:h-10 sm:w-10">
            <ToriiMark className="h-4 w-6 text-white" />
          </span>
          <span>
            <span className="block text-[8px] font-black leading-none tracking-[0.2em] text-white/45">芥末</span>
            <span className="font-street block text-lg leading-none sm:text-xl">WASABI</span>
          </span>
        </Link>

        <div className="ml-auto hidden h-full items-stretch lg:flex">
          {links.map((link) => {
            const active = link.href === "/" ? pathname === "/" : pathname.startsWith(link.href);
            return (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  "relative flex items-center border-l border-white/10 px-5 text-[11px] font-black uppercase tracking-[0.1em] text-white/50 transition-colors hover:text-white",
                  active && "text-white after:absolute after:inset-x-4 after:bottom-0 after:h-1 after:bg-[var(--menu-red)]"
                )}
              >
                {link.label}
              </Link>
            );
          })}
        </div>

        <div className="ml-auto flex items-center border-l border-white/10 lg:ml-0">
          <div className="grid h-12 w-11 place-items-center sm:h-14 sm:w-12 [&>button]:border-0 [&>button]:bg-transparent [&>button]:text-white/65">
            <ThemeToggle />
          </div>
          <div className="grid h-12 w-11 place-items-center border-l border-white/10 sm:h-14 sm:w-12">
            <NotificationBell />
          </div>
          <Link
            href="/menu"
            aria-label={count > 0 ? `Open menu, ${count} items in basket` : "Open menu"}
            className="relative grid h-12 w-11 place-items-center border-l border-white/10 text-white/65 transition-colors hover:bg-[var(--menu-red)] hover:text-white sm:h-14 sm:w-12"
          >
            <ShoppingBag className="h-[18px] w-[18px]" />
            {count > 0 && (
              <span className="absolute right-1.5 top-1.5 grid h-4 min-w-4 place-items-center bg-[var(--menu-red)] px-1 text-[9px] font-black text-white">
                {count > 99 ? "99+" : count}
              </span>
            )}
          </Link>
          <Link
            href={hydrated && isAuthenticated ? "/account" : "/login"}
            aria-label={hydrated && isAuthenticated ? "Account" : "Sign in"}
            className="grid h-12 w-11 place-items-center border-l border-white/10 text-white/65 transition-colors hover:bg-white hover:text-[var(--menu-ink)] sm:h-14 sm:w-12"
          >
            <UserRound className="h-[18px] w-[18px]" />
          </Link>
        </div>
      </div>
    </nav>
  );
}
