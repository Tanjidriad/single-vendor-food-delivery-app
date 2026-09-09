"use client";

import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { Bell } from "lucide-react";

import { useAuth } from "@/lib/auth/use-auth";
import { useUnreadCount } from "@/lib/api/queries/notifications";

/**
 * Nav bell with an animated unread badge. Only renders for signed-in users;
 * the badge pops in and gently pulses when there's something new to read.
 */
export function NotificationBell() {
  const { isAuthenticated, hydrated } = useAuth();
  const unread = useUnreadCount();

  if (!hydrated || !isAuthenticated) return null;

  return (
    <Link
      href="/notifications"
      aria-label={
        unread > 0 ? `Notifications, ${unread} unread` : "Notifications"
      }
      className="relative grid h-11 w-11 place-items-center rounded-full border border-white/15 bg-white/5 text-white transition-colors hover:bg-white/10 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_35%,transparent)]"
    >
      <Bell className="h-[18px] w-[18px]" />
      <AnimatePresence>
        {unread > 0 && (
          <motion.span
            key="badge"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            transition={{ type: "spring", stiffness: 500, damping: 22 }}
            className="absolute -right-1 -top-1 grid h-5 min-w-5 place-items-center rounded-full bg-[var(--brand)] px-1 text-[10px] font-bold text-white"
          >
            <span className="absolute inset-0 animate-ping rounded-full bg-[var(--brand)] opacity-60" />
            <span className="relative">{unread > 99 ? "99+" : unread}</span>
          </motion.span>
        )}
      </AnimatePresence>
    </Link>
  );
}
