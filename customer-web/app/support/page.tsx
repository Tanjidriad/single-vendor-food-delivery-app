"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { LifeBuoy, Loader2 } from "lucide-react";

import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth/use-auth";
import { useComplaints } from "@/lib/api/queries/complaints";
import { formatTk } from "@/lib/utils";
import type { Complaint, ComplaintStatus } from "@/types";

const STATUS_STYLES: Record<ComplaintStatus, string> = {
  OPEN: "bg-[color-mix(in_srgb,var(--warning)_16%,transparent)] text-[var(--warning)]",
  IN_REVIEW:
    "bg-[color-mix(in_srgb,var(--mustard)_18%,transparent)] text-[var(--mustard)]",
  RESOLVED:
    "bg-[color-mix(in_srgb,var(--success)_16%,transparent)] text-[var(--success)]",
  REJECTED:
    "bg-[color-mix(in_srgb,var(--error)_14%,transparent)] text-[var(--error)]",
};

const STATUS_LABELS: Record<ComplaintStatus, string> = {
  OPEN: "Open",
  IN_REVIEW: "In review",
  RESOLVED: "Resolved",
  REJECTED: "Rejected",
};

export default function SupportPage() {
  const { isAuthenticated, hydrated } = useAuth();
  const { data: complaints, isLoading, isError, refetch } = useComplaints();

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
          <span className="grid h-16 w-16 place-items-center bg-[var(--menu-red)] text-white">
            <LifeBuoy className="h-7 w-7" />
          </span>
          <h1 className="font-street mt-5 text-3xl">
            Sign in to get support
          </h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            Track your reports and refund requests in one place.
          </p>
          <Link href="/login?next=/support" className="mt-6">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  const list = complaints ?? [];

  return (
    <Shell>
      <div className="mx-auto max-w-[980px] px-4 py-10 sm:px-6 sm:py-16 lg:py-20">
        <p className="wasabi-page-kicker">
          Support
        </p>
        <h1 className="font-street mt-4 text-[clamp(3rem,9vw,6.8rem)] leading-[0.82]">
          We&apos;ll sort<br />the order.
        </h1>
        <p className="mt-2 max-w-[52ch] text-sm text-[var(--foreground-dim)]">
          Raise a problem from any past order and we&apos;ll follow up. Your reports
          and their status show up here.
        </p>

        {isLoading && (
          <div className="flex justify-center py-20">
            <Loader2 className="h-7 w-7 animate-spin text-[var(--foreground-mute)]" />
          </div>
        )}

        {isError && (
          <div className="mt-8 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-8 text-center">
            <p className="text-sm text-[var(--foreground-dim)]">
              We couldn&apos;t load your reports just now.
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
              <LifeBuoy className="h-6 w-6" />
            </span>
            <h2 className="font-street mt-4 text-2xl">
              No reports yet
            </h2>
            <p className="mt-2 max-w-[36ch] text-sm text-[var(--foreground-dim)]">
              If something goes wrong with an order, open it and tap “Report a
              problem”.
            </p>
            <Link href="/orders" className="mt-6">
              <Button size="lg">Go to your orders</Button>
            </Link>
          </div>
        )}

        {!isLoading && list.length > 0 && (
          <ul className="mt-8 space-y-3">
            {list.map((c, i) => (
              <ComplaintCard key={c.id} complaint={c} index={i} />
            ))}
          </ul>
        )}
      </div>
    </Shell>
  );
}

function ComplaintCard({
  complaint,
  index,
}: {
  complaint: Complaint;
  index: number;
}) {
  const date = new Date(complaint.createdAt);
  const dateLabel = Number.isNaN(date.getTime())
    ? ""
    : date.toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
      });
  const serial = complaint.order?.dailySerial
    ? `#${String(complaint.order.dailySerial).padStart(3, "0")}`
    : complaint.order?.orderNumber
      ? `#${complaint.order.orderNumber.slice(-6)}`
      : null;

  return (
    <motion.li
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1], delay: (index % 6) * 0.04 }}
    >
      <div className="border border-black/15 bg-[var(--menu-rice)] p-4 transition-colors hover:border-[var(--menu-red)] dark:border-white/15 sm:p-5">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-[var(--surface-sunken)] px-2.5 py-0.5 text-[11px] font-bold text-[var(--foreground-dim)]">
                {complaint.type === "REFUND_REQUEST" ? "Refund" : "Complaint"}
              </span>
              {serial && (
                <Link
                  href={`/orders/${complaint.orderId}`}
                  className="text-[12px] font-bold text-[var(--brand)] underline underline-offset-2"
                >
                  {serial}
                </Link>
              )}
            </div>
            <h3 className="mt-2 font-display text-base font-black">
              {complaint.subject}
            </h3>
          </div>
          <span
            className={`flex-none rounded-full px-2.5 py-1 text-[11px] font-bold ${STATUS_STYLES[complaint.status]}`}
          >
            {STATUS_LABELS[complaint.status]}
          </span>
        </div>

        <p className="mt-2 text-sm leading-6 text-[var(--foreground-dim)]">
          {complaint.description}
        </p>

        {complaint.type === "REFUND_REQUEST" &&
          complaint.refundAmount != null &&
          complaint.refundAmount > 0 && (
            <p className="mt-2 text-sm font-bold tabular-nums">
              Requested: {formatTk(complaint.refundAmount)}
            </p>
          )}

        {complaint.resolutionNote && (
          <div className="mt-3 rounded-[12px] border border-[var(--border-subtle)] bg-[var(--surface-sunken)] p-3">
            <p className="text-[11px] font-bold uppercase tracking-[0.14em] text-[var(--foreground-mute)]">
              Response
            </p>
            <p className="mt-1 text-sm text-[var(--foreground-dim)]">
              {complaint.resolutionNote}
            </p>
          </div>
        )}

        {dateLabel && (
          <p className="mt-3 text-[12px] text-[var(--foreground-mute)]">
            {dateLabel}
          </p>
        )}
      </div>
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
