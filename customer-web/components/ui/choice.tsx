"use client";

import * as React from "react";

import { cn } from "@/lib/utils";

type BaseProps = Omit<React.InputHTMLAttributes<HTMLInputElement>, "type"> & {
  label: React.ReactNode;
  /** Secondary line, e.g. an add-on price or a delivery caveat. */
  description?: React.ReactNode;
  /** Right-aligned value, e.g. "+ 30 Tk". */
  trailing?: React.ReactNode;
};

/**
 * Selection state is projected from the label so it can reach the tick and the
 * knob, which sit inside the control. The motion itself lives in globals.css:
 * Tailwind's group-has-* compiles with :where() and ties specificity with the
 * base utility, so which one wins comes down to source order.
 */
function Row({
  kind,
  label,
  description,
  trailing,
  className,
  ...props
}: BaseProps & { kind: "checkbox" | "radio" }) {
  return (
    <label
      className={cn(
        "group flex cursor-pointer items-start gap-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3.5",
        "transition-[border-color,background-color] duration-200 ease-out",
        "hover:border-[var(--foreground-mute)]",
        "has-[:checked]:border-[var(--brand)] has-[:checked]:bg-[color-mix(in_srgb,var(--brand)_6%,var(--surface))]",
        "has-[:focus-visible]:shadow-[0_0_0_4px_color-mix(in_srgb,var(--brand)_16%,transparent)]",
        "has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50 has-[:disabled]:hover:border-[var(--border)]",
        className
      )}
    >
      <input type={kind} className="sr-only" {...props} />

      <span
        aria-hidden
        className={cn(
          "relative mt-px grid h-5 w-5 flex-none place-items-center border-[1.5px] border-[var(--border)] bg-[var(--surface)]",
          "transition-colors duration-200 ease-out",
          kind === "radio" ? "rounded-full" : "rounded-md",
          "group-has-[:checked]:border-[var(--brand)] group-has-[:checked]:bg-[var(--brand)]"
        )}
      >
        {kind === "checkbox" ? (
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="3.2" strokeLinecap="round" strokeLinejoin="round">
            <path className="choice-tick" d="M5 12.5l4.5 4.5L19 7.5" />
          </svg>
        ) : (
          <span className="choice-dot h-1.5 w-1.5 rounded-full bg-white" />
        )}
      </span>

      <span className="flex min-w-0 flex-1 flex-col">
        <span className="text-[14px] font-semibold leading-tight text-[var(--foreground)]">
          {label}
        </span>
        {description && (
          <span className="mt-1 text-[12.5px] leading-snug text-[var(--foreground-mute)]">
            {description}
          </span>
        )}
      </span>

      {trailing && (
        <span className="ml-2 flex-none self-center text-[14px] font-semibold tabular-nums text-[var(--foreground)]">
          {trailing}
        </span>
      )}
    </label>
  );
}

export function Checkbox(props: BaseProps) {
  return <Row kind="checkbox" {...props} />;
}

export function Radio(props: BaseProps) {
  return <Row kind="radio" {...props} />;
}

/** Toggle for a setting that applies immediately (no Save button). */
export function Switch({
  label,
  description,
  className,
  ...props
}: Omit<React.InputHTMLAttributes<HTMLInputElement>, "type"> & {
  label: React.ReactNode;
  description?: React.ReactNode;
}) {
  return (
    <label
      className={cn(
        "group flex cursor-pointer items-center justify-between gap-5",
        "has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50",
        className
      )}
    >
      <span className="flex min-w-0 flex-col">
        <span className="text-[14px] font-semibold text-[var(--foreground)]">{label}</span>
        {description && (
          <span className="mt-0.5 text-[12.5px] text-[var(--foreground-mute)]">{description}</span>
        )}
      </span>

      <input type="checkbox" role="switch" className="sr-only" {...props} />

      <span
        aria-hidden
        className={cn(
          "relative h-[26px] w-[46px] flex-none rounded-full border border-[var(--border)] bg-[var(--surface-sunken)]",
          "transition-colors duration-200 ease-out",
          "group-has-[:checked]:border-[var(--brand)] group-has-[:checked]:bg-[var(--brand)]",
          "group-has-[:focus-visible]:shadow-[0_0_0_4px_color-mix(in_srgb,var(--brand)_16%,transparent)]"
        )}
      >
        <span className="choice-knob absolute left-[3px] top-[3px] h-[18px] w-[18px] rounded-full shadow-[0_1px_2px_rgba(0,0,0,0.18)]" />
      </span>
    </label>
  );
}

/**
 * Quantity stepper for a basket line. Digits are tabular so the row does not
 * reflow as the count crosses 9, and the minus turns into a bin at 1 so the
 * customer is never left guessing how to remove something.
 */
export function QuantityStepper({
  value,
  onChange,
  min = 1,
  max = 99,
  label = "quantity",
  className,
}: {
  value: number;
  onChange: (next: number) => void;
  min?: number;
  max?: number;
  label?: string;
  className?: string;
}) {
  const atMin = value <= min;
  const btn =
    "grid h-9 w-9 place-items-center rounded-full text-[var(--foreground)] transition-[background-color,transform] duration-150 ease-out " +
    "hover:bg-[var(--surface-sunken)] active:scale-90 focus-visible:outline-none " +
    "focus-visible:shadow-[0_0_0_4px_color-mix(in_srgb,var(--brand)_16%,transparent)] disabled:opacity-40 disabled:hover:bg-transparent";

  return (
    <div
      className={cn(
        "inline-flex items-center gap-1 rounded-full border border-[var(--border)] bg-[var(--surface)] p-1",
        className
      )}
    >
      <button
        type="button"
        className={btn}
        onClick={() => onChange(Math.max(min - 1, value - 1))}
        aria-label={atMin ? `Remove ${label}` : `Decrease ${label}`}
      >
        {atMin ? (
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
            <path d="M6 7h12l-1 12.5a2 2 0 0 1-2 1.5H9a2 2 0 0 1-2-1.5z" />
            <path d="M9.5 7V5.5a2.5 2.5 0 0 1 5 0V7" />
          </svg>
        ) : (
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
            <path d="M5 12h14" />
          </svg>
        )}
      </button>

      <span
        aria-live="polite"
        className="min-w-6 text-center text-[14px] font-semibold tabular-nums text-[var(--foreground)]"
      >
        {value}
      </span>

      <button
        type="button"
        className={btn}
        onClick={() => onChange(Math.min(max, value + 1))}
        disabled={value >= max}
        aria-label={`Increase ${label}`}
      >
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
          <path d="M12 5v14M5 12h14" />
        </svg>
      </button>
    </div>
  );
}
