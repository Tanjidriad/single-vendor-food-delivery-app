"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Package, Tag, UtensilsCrossed, UserRound } from "lucide-react";

import { useAuth } from "@/lib/auth/use-auth";
import { useCartStore } from "@/store/cart-store";
import { cn } from "@/lib/utils";

const TABS = [
  { href: "/", label: "Home", icon: Home, match: (p: string) => p === "/" },
  {
    href: "/offers",
    label: "Offers",
    icon: Tag,
    match: (p: string) => p.startsWith("/offers"),
  },
  {
    href: "/menu",
    label: "Menu",
    icon: UtensilsCrossed,
    match: (p: string) => p.startsWith("/menu"),
  },
  {
    href: "/orders",
    label: "Orders",
    icon: Package,
    match: (p: string) => p.startsWith("/orders"),
    auth: true,
  },
  {
    href: "/account",
    label: "Account",
    icon: UserRound,
    match: (p: string) => p.startsWith("/account") || p.startsWith("/login"),
  },
] as const;

/** Native-style bottom tabs — mobile only. Hidden on checkout. */
export function MobileBottomNav() {
  const pathname = usePathname();
  const { isAuthenticated, hydrated } = useAuth();
  const cartCount = useCartStore((s) =>
    s.lines.reduce((n, l) => n + l.quantity, 0)
  );

  if (pathname.startsWith("/checkout")) return null;

  return (
    <nav
      aria-label="Primary"
      className="fixed inset-x-0 bottom-0 z-[var(--z-drawer)] border-t-4 border-[var(--brand)] bg-[var(--ink)] text-white sm:hidden"
      style={{ paddingBottom: "env(safe-area-inset-bottom)" }}
    >
      <div className="mx-auto grid h-[60px] max-w-lg grid-cols-5">
        {TABS.map((tab) => {
          const href =
            "auth" in tab && tab.auth && hydrated && !isAuthenticated
              ? `/login?next=${tab.href}`
              : tab.href === "/account" && hydrated && !isAuthenticated
                ? "/login?next=/account"
                : tab.href;
          const active = tab.match(pathname);
          const Icon = tab.icon;
          const showBadge = tab.href === "/menu" && cartCount > 0;

          return (
            <Link
              key={tab.label}
              href={href}
              className={cn(
                "relative flex flex-col items-center justify-center gap-0.5 text-[10px] font-bold transition-colors",
                active
                  ? "bg-[var(--brand)] text-white"
                  : "text-white/45 active:text-white"
              )}
            >
              <span className="relative">
                <Icon
                  className={cn("h-5 w-5", active && "stroke-[2.5px]")}
                  strokeWidth={active ? 2.5 : 2}
                />
                {showBadge && (
                  <span className="absolute -right-2.5 -top-1.5 grid h-4 min-w-4 place-items-center bg-white px-1 text-[9px] font-black text-[var(--brand)]">
                    {cartCount > 99 ? "99+" : cartCount}
                  </span>
                )}
              </span>
              {tab.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
