"use client";

import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const chipVariants = cva(
  "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full border font-semibold leading-none tracking-[0.01em]",
  {
    variants: {
      tone: {
        neutral: "border-[var(--border)] bg-[var(--surface)] text-[var(--foreground-dim)]",
        brand:
          "border-[var(--brand)] bg-[color-mix(in_srgb,var(--brand)_10%,var(--surface))] text-[var(--brand)]",
        success:
          "border-[color-mix(in_srgb,var(--success)_55%,transparent)] bg-[color-mix(in_srgb,var(--success)_10%,var(--surface))] text-[var(--success)]",
        warning:
          "border-[color-mix(in_srgb,var(--warning)_55%,transparent)] bg-[color-mix(in_srgb,var(--warning)_12%,var(--surface))] text-[var(--warning)]",
        danger:
          "border-[color-mix(in_srgb,var(--error)_55%,transparent)] bg-[color-mix(in_srgb,var(--error)_10%,var(--surface))] text-[var(--error)]",
        solid: "border-[var(--ink)] bg-[var(--ink)] text-[var(--on-ink)]",
      },
      size: {
        sm: "h-6 px-2.5 text-[11px]",
        md: "h-8 px-3.5 text-[12px]",
      },
    },
    defaultVariants: { tone: "neutral", size: "md" },
  }
);

export interface ChipProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof chipVariants> {
  /** Pulsing dot for a state that is still moving, e.g. "preparing". */
  dot?: boolean;
  /** Renders a remove button; the chip stays a span so it can sit inside links. */
  onRemove?: () => void;
  removeLabel?: string;
}

export function Chip({
  className,
  tone,
  size,
  dot,
  onRemove,
  removeLabel,
  children,
  ...props
}: ChipProps) {
  return (
    <span
      className={cn(chipVariants({ tone, size }), className)}
      {...props}
    >
      {dot && (
        <span aria-hidden className="relative flex h-1.5 w-1.5 flex-none">
          <span className="absolute inset-0 animate-ping rounded-full bg-current opacity-60" />
          <span className="relative h-1.5 w-1.5 rounded-full bg-current" />
        </span>
      )}
      {children}
      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          aria-label={removeLabel ?? "Remove"}
          className="-mr-1 ml-0.5 grid h-4 w-4 place-items-center opacity-55 transition-opacity hover:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-current"
        >
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.4">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>
      )}
    </span>
  );
}

/**
 * Toggleable chip for the menu category rail. Selected state is carried by fill
 * and the offset shadow, not colour alone, so it survives a mono screen.
 */
export function FilterChip({
  selected,
  count,
  className,
  children,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  selected?: boolean;
  /** Item count, shown as a trailing tally. */
  count?: number;
}) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      className={cn(
        "inline-flex h-9 items-center gap-2 whitespace-nowrap rounded-full border px-4 text-[12.5px] font-semibold leading-none",
        "transition-[background-color,border-color,color,transform] duration-200 ease-out active:scale-95",
        "focus-visible:outline-none focus-visible:shadow-[0_0_0_4px_color-mix(in_srgb,var(--brand)_16%,transparent)]",
        "disabled:cursor-not-allowed disabled:opacity-50",
        selected
          ? "border-[var(--brand)] bg-[var(--brand)] text-white"
          : "border-[var(--border)] bg-[var(--surface)] text-[var(--foreground-dim)] hover:border-[var(--foreground-mute)] hover:text-[var(--foreground)]",
        className
      )}
      {...props}
    >
      {children}
      {typeof count === "number" && (
        <span className={cn("tabular-nums", selected ? "text-white/70" : "text-[var(--foreground-mute)]")}>
          {count}
        </span>
      )}
    </button>
  );
}
