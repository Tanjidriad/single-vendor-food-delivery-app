"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Search, ShoppingBag, UserRound } from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { ThemeToggle } from "@/components/theme-toggle";
import { NotificationBell } from "@/components/notifications/notification-bell";
import { useAuth } from "@/lib/auth/use-auth";
import { useCartStore } from "@/store/cart-store";
import { cn } from "@/lib/utils";

/** Scroll distance after which the bar condenses. */
const CONDENSE_AFTER = 70;

export function LandingNav() {
  const pathname = usePathname();
  const { isAuthenticated, hydrated } = useAuth();
  const [condensed, setCondensed] = useState(false);
  const count = useCartStore((state) =>
    state.lines.reduce((total, line) => total + line.quantity, 0)
  );

  // Condense once the hero starts leaving, so scrolling the menu keeps more of
  // the screen without ever losing the basket or account controls.
  useEffect(() => {
    let queued = false;
    const onScroll = () => {
      if (queued) return;
      queued = true;
      requestAnimationFrame(() => {
        setCondensed(window.scrollY > CONDENSE_AFTER);
        queued = false;
      });
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const links = [
    { href: "/", label: "Home" },
    { href: "/menu", label: "Menu" },
    { href: "/offers", label: "Offers" },
    ...(hydrated && isAuthenticated ? [{ href: "/orders", label: "Orders" }] : []),
  ];

  return (
    <nav className="sticky top-0 z-[var(--z-sticky)] w-full border-b-4 border-[var(--menu-red)] bg-[var(--menu-bar)] text-white">
      <div
        className={cn(
          "mx-auto flex max-w-[1440px] items-center px-4 transition-[height] duration-300 ease-out sm:px-6 lg:px-10",
          condensed ? "h-14 sm:h-14" : "h-16 sm:h-[72px]"
        )}
      >
        <Link href="/" aria-label="Wasabi home" className="flex items-center gap-2.5 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200">
          <span
            className={cn(
              "grid place-items-center bg-[var(--menu-red)] transition-[width,height] duration-300 ease-out",
              condensed ? "h-8 w-8" : "h-9 w-9 sm:h-10 sm:w-10"
            )}
          >
            <ToriiMark className="h-4 w-6 text-white" />
          </span>
          <span>
            <span className="block text-[8px] font-black leading-none tracking-[0.2em] text-white/45">芥末</span>
            <span
              className={cn(
                "font-street block leading-none transition-[font-size] duration-300 ease-out",
                condensed ? "text-base sm:text-lg" : "text-lg sm:text-xl"
              )}
            >
              WASABI
            </span>
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

        <div className="ml-auto flex items-center self-stretch border-l border-white/10 lg:ml-0">
          {/* Points at /menu, which is where the real dish search lives. */}
          <Link
            href="/menu"
            aria-label="Search the menu"
            className="grid w-11 place-items-center self-stretch text-white/65 transition-colors hover:bg-[var(--menu-red)] hover:text-white sm:w-12"
          >
            <Search className="h-[18px] w-[18px]" />
          </Link>
          <div className="grid w-11 place-items-center self-stretch border-l border-white/10 sm:w-12 [&>button]:border-0 [&>button]:bg-transparent [&>button]:text-white/65">
            <ThemeToggle />
          </div>
          {/* The bell renders nothing when signed out, so the cell must go too —
              otherwise the bar keeps a 44px hole and a stray divider. */}
          {hydrated && isAuthenticated && (
            <div className="grid w-11 place-items-center self-stretch border-l border-white/10 sm:w-12">
              <NotificationBell />
            </div>
          )}
          <Link
            href="/menu"
            aria-label={count > 0 ? `Open menu, ${count} items in basket` : "Open menu"}
            className="relative grid w-11 place-items-center self-stretch border-l border-white/10 text-white/65 transition-colors hover:bg-[var(--menu-red)] hover:text-white sm:w-12"
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
            className="grid w-11 place-items-center self-stretch border-l border-white/10 text-white/65 transition-colors hover:bg-white hover:text-[var(--menu-bar)] sm:w-12"
          >
            <UserRound className="h-[18px] w-[18px]" />
          </Link>
        </div>
      </div>
    </nav>
  );
}
