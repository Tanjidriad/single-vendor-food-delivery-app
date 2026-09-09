"use client";

import Link from "next/link";
import { Bike, ChevronRight, Loader2, Package, ShoppingBag } from "lucide-react";

import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth/use-auth";
import { useOrders } from "@/lib/api/queries/orders";
import { formatTk } from "@/lib/utils";
import { STATUS_LABELS, isTerminal } from "@/lib/order-status";
import type { Order } from "@/types";

export default function OrdersPage() {
  const { isAuthenticated, hydrated } = useAuth();
  const { data: orders, isLoading, isError, refetch } = useOrders();

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
          <span className="grid h-16 w-16 place-items-center bg-[var(--menu-red)] text-white">
            <Package className="h-7 w-7" />
          </span>
          <h1 className="font-street mt-5 text-3xl">
            Sign in to see your orders
          </h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            Track active deliveries and reorder past favourites.
          </p>
          <Link href="/login?next=/orders" className="mt-6">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  const list = orders ?? [];
  const active = list.filter((o) => !isTerminal(o.status));
  const past = list.filter((o) => isTerminal(o.status));

  return (
    <Shell>
      <div className="mx-auto max-w-[980px] px-4 py-10 sm:px-6 sm:py-16 lg:py-20">
        <p className="wasabi-page-kicker">
          Your orders
        </p>
        <h1 className="font-street mt-4 text-[clamp(3rem,9vw,6.8rem)] leading-[0.82]">
          From kitchen<br />to your door.
        </h1>

        {isLoading && (
          <div className="flex justify-center py-20">
            <Loader2 className="h-7 w-7 animate-spin text-[var(--foreground-mute)]" />
          </div>
        )}

        {isError && (
          <div className="mt-8 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-8 text-center">
            <p className="text-sm text-[var(--foreground-dim)]">
              We couldn&apos;t load your orders just now.
            </p>
            <button
              onClick={() => refetch()}
              className="mt-3 text-sm font-semibold text-[var(--brand)] underline underline-offset-4"
            >
              Try again
            </button>
          </div>
        )}

        {!isLoading && !isError && list.length === 0 && (
          <div className="mt-10 flex flex-col items-center border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] px-6 py-16 text-center">
            <span className="grid h-14 w-14 place-items-center bg-[var(--menu-red)] text-white">
              <ShoppingBag className="h-6 w-6" />
            </span>
            <h2 className="font-street mt-4 text-2xl">No orders yet</h2>
            <p className="mt-2 max-w-[36ch] text-sm text-[var(--foreground-dim)]">
              When you place an order, it will show up here with live tracking.
            </p>
            <Link href="/menu" className="mt-6">
              <Button size="lg">Browse the menu</Button>
            </Link>
          </div>
        )}

        {!isLoading && active.length > 0 && (
          <section className="mt-8">
            <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-[var(--foreground-mute)]">
              Active
            </h2>
            <ul className="mt-3 space-y-3">
              {active.map((order) => (
                <OrderCard key={order.id} order={order} highlight />
              ))}
            </ul>
          </section>
        )}

        {!isLoading && past.length > 0 && (
          <section className="mt-10">
            <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-[var(--foreground-mute)]">
              Past
            </h2>
            <ul className="mt-3 space-y-3">
              {past.map((order) => (
                <OrderCard key={order.id} order={order} />
              ))}
            </ul>
          </section>
        )}
      </div>
    </Shell>
  );
}

function OrderCard({ order, highlight }: { order: Order; highlight?: boolean }) {
  const serial = order.dailySerial
    ? `#${String(order.dailySerial).padStart(3, "0")}`
    : `#${order.orderNumber.slice(-6)}`;
  const itemCount = order.items.reduce((n, i) => n + i.quantity, 0);
  const date = new Date(order.placedAt || order.createdAt);
  const dateLabel = Number.isNaN(date.getTime())
    ? ""
    : date.toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });

  return (
    <li>
      <Link
        href={`/orders/${order.id}`}
        className={`flex items-center gap-4 border bg-[var(--menu-rice)] p-4 transition-colors sm:p-5 ${
          highlight
            ? "border-[var(--brand)] shadow-[0_8px_24px_rgba(210,31,60,0.1)]"
            : "border-[var(--border-subtle)] hover:border-[var(--foreground-mute)]"
        }`}
      >
        <span
          className={`grid h-11 w-11 flex-none place-items-center ${
            highlight
              ? "bg-[color-mix(in_srgb,var(--brand)_12%,transparent)] text-[var(--brand)]"
              : "bg-[var(--surface-sunken)] text-[var(--foreground-dim)]"
          }`}
        >
          {order.orderType === "DELIVERY" ? (
            <Bike className="h-5 w-5" />
          ) : (
            <ShoppingBag className="h-5 w-5" />
          )}
        </span>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-street text-base">{serial}</p>
            <span
              className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
                highlight
                  ? "bg-[var(--brand)] text-white"
                  : "bg-[var(--surface-sunken)] text-[var(--foreground-dim)]"
              }`}
            >
              {STATUS_LABELS[order.status]}
            </span>
          </div>
          <p className="mt-1 truncate text-sm text-[var(--foreground-dim)]">
            {itemCount} {itemCount === 1 ? "item" : "items"} ·{" "}
            {order.orderType === "DELIVERY" ? "Delivery" : "Pickup"}
            {dateLabel ? ` · ${dateLabel}` : ""}
          </p>
        </div>

        <div className="flex flex-none items-center gap-2">
          <span className="text-sm font-bold tabular-nums">
            {formatTk(order.grandTotal)}
          </span>
          <ChevronRight className="h-4 w-4 text-[var(--foreground-mute)]" />
        </div>
      </Link>
    </li>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="wasabi-app-shell min-h-dvh">
      <div className="hidden sm:block">
        <TopBar />
      </div>
      <LandingNav />
      <main>
        {children}
      </main>
      <LandingFooter />
      <MobileBottomNav />
    </div>
  );
}
