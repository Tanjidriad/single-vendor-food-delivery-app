import * as React from "react";

import { cn } from "@/lib/utils";

/**
 * Placeholder with a sweeping highlight. Give it the size of the thing it
 * stands in for — a skeleton that does not match the real shape reads as a
 * layout bug the moment the content lands.
 */
export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div aria-hidden className={cn("skeleton-sweep", className)} {...props} />;
}

export function Spinner({ className, label = "Loading" }: { className?: string; label?: string }) {
  return (
    <span role="status" aria-label={label} className={cn("inline-block", className)}>
      <svg viewBox="0 0 24 24" fill="none" className="h-full w-full animate-spin">
        <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2.6" className="opacity-20" />
        <path d="M21 12a9 9 0 0 0-9-9" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" />
      </svg>
    </span>
  );
}

/**
 * For a genuinely empty list — never for one that is still loading. The icon
 * sits on the brand square so an empty screen still looks composed.
 */
export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("flex flex-col items-center px-6 py-14 text-center", className)}>
      {icon && (
        <span className="mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-[color-mix(in_srgb,var(--brand)_12%,var(--surface))] text-[var(--brand)]">
          {icon}
        </span>
      )}
      <p className="text-[17px] font-bold tracking-[-0.01em] text-[var(--foreground)]">
        {title}
      </p>
      {description && (
        <p className="mt-2.5 max-w-[38ch] text-[13px] leading-relaxed text-[var(--foreground-mute)]">
          {description}
        </p>
      )}
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
}

/**
 * Receipt-style row for totals. Tabular digits and a dotted leader so the eye
 * tracks label to amount without the two drifting apart on wide screens.
 */
export function SummaryRow({
  label,
  value,
  emphasis,
  className,
}: {
  label: React.ReactNode;
  value: React.ReactNode;
  /** Use for the grand total only. */
  emphasis?: boolean;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex items-baseline gap-3",
        emphasis
          ? "border-t border-[var(--border)] pt-3 text-[15px] font-bold text-[var(--foreground)]"
          : "text-[13px] text-[var(--foreground-dim)]",
        className
      )}
    >
      <span className={undefined}>{label}</span>
      <span
        aria-hidden
        className="min-w-4 flex-1 translate-y-[-3px] border-b border-dashed border-[var(--border)]"
      />
      <span className="tabular-nums tracking-[-0.01em]">{value}</span>
    </div>
  );
}
