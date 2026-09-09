"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import {
  Bell,
  CheckCheck,
  Gift,
  Loader2,
  Megaphone,
  Package,
} from "lucide-react";

import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth/use-auth";
import {
  useMarkNotificationRead,
  useNotifications,
} from "@/lib/api/queries/notifications";
import type { AppNotification } from "@/types";

const ICONS: Record<string, typeof Bell> = {
  ORDER_UPDATE: Package,
  PROMOTION: Gift,
  ANNOUNCEMENT: Megaphone,
  GENERAL: Bell,
};

function NotificationIcon({ type }: { type?: string | null }) {
  const IconComponent = (type && ICONS[type]) || Bell;
  return <IconComponent className="h-5 w-5" />;
}


export default function NotificationsPage() {
  const { isAuthenticated, hydrated } = useAuth();
  const { data: notifications, isLoading, isError, refetch } = useNotifications();
  const markRead = useMarkNotificationRead();

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
          <span className="grid h-16 w-16 place-items-center bg-[var(--menu-red)] text-white">
            <Bell className="h-7 w-7" />
          </span>
          <h1 className="font-street mt-5 text-3xl">
            Sign in to see notifications
          </h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            Order updates, offers and news land right here.
          </p>
          <Link href="/login?next=/notifications" className="mt-6">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  const list = notifications ?? [];
  const unread = list.filter((n) => !n.readAt);

  return (
    <Shell>
      <div className="mx-auto max-w-[920px] px-4 py-10 sm:px-6 sm:py-16 lg:py-20">
        <div className="flex items-end justify-between gap-4">
          <div>
            <p className="wasabi-page-kicker">
              Inbox
            </p>
            <h1 className="font-street mt-4 text-[clamp(3rem,9vw,6.8rem)] leading-[0.82]">
              Kitchen<br />signals.
            </h1>
          </div>
          {unread.length > 0 && (
            <Button
              variant="light"
              size="sm"
              disabled={markRead.isPending}
              onClick={() => unread.forEach((n) => markRead.mutate(n.id))}
            >
              <CheckCheck className="h-4 w-4" /> Mark all read
            </Button>
          )}
        </div>

        {isLoading && (
          <div className="flex justify-center py-20">
            <Loader2 className="h-7 w-7 animate-spin text-[var(--foreground-mute)]" />
          </div>
        )}

        {isError && (
          <div className="mt-8 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-8 text-center">
            <p className="text-sm text-[var(--foreground-dim)]">
              We couldn&apos;t load your notifications just now.
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
              <Bell className="h-6 w-6" />
            </span>
            <h2 className="font-street mt-4 text-2xl">
              You&apos;re all caught up
            </h2>
            <p className="mt-2 max-w-[36ch] text-sm text-[var(--foreground-dim)]">
              Order updates and offers will show up here as they happen.
            </p>
          </div>
        )}

        {!isLoading && list.length > 0 && (
          <ul className="mt-8 space-y-2.5">
            {list.map((n, i) => (
              <NotificationRow
                key={n.id}
                notification={n}
                index={i}
                onRead={() => {
                  if (!n.readAt) markRead.mutate(n.id);
                }}
              />
            ))}
          </ul>
        )}
      </div>
    </Shell>
  );
}

function NotificationRow({
  notification,
  index,
  onRead,
}: {
  notification: AppNotification;
  index: number;
  onRead: () => void;
}) {
  const router = useRouter();
  const unread = !notification.readAt;


  const when = new Date(notification.createdAt);
  const timeLabel = Number.isNaN(when.getTime())
    ? ""
    : when.toLocaleString("en-GB", {
        day: "numeric",
        month: "short",
        hour: "2-digit",
        minute: "2-digit",
      });

  function handleClick() {
    onRead();
    if (notification.orderId) {
      router.push(`/orders/${notification.orderId}`);
    }
  }


  return (
    <motion.li
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1], delay: (index % 8) * 0.03 }}
    >
      <button
        onClick={handleClick}
        className={`flex w-full items-start gap-3.5 border p-4 text-left transition-colors ${
          unread
            ? "border-[color-mix(in_srgb,var(--brand)_24%,transparent)] bg-[color-mix(in_srgb,var(--brand)_5%,var(--surface))]"
            : "border-[var(--border-subtle)] bg-[var(--surface)] hover:border-[var(--foreground-mute)]"
        }`}
      >
        <span
          className={`grid h-10 w-10 flex-none place-items-center ${
            unread
              ? "bg-[var(--brand)] text-white"
              : "bg-[var(--surface-sunken)] text-[var(--foreground-dim)]"
          }`}
        >
          <NotificationIcon type={notification.type} />
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-3">
            <p className="text-sm font-bold leading-snug">{notification.title}</p>
            {unread && (
              <span className="mt-1 h-2 w-2 flex-none rounded-full bg-[var(--brand)]" />
            )}
          </div>
          {notification.body && (
            <p className="mt-1 text-[13px] leading-6 text-[var(--foreground-dim)]">
              {notification.body}
            </p>
          )}
          {timeLabel && (
            <p className="mt-1.5 text-[12px] text-[var(--foreground-mute)]">
              {timeLabel}
            </p>
          )}
        </div>
      </button>
    </motion.li>
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
