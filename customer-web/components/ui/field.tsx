"use client";

import * as React from "react";

import { cn } from "@/lib/utils";

interface FieldProps {
  label: string;
  /** Quiet guidance shown under the control until an error replaces it. */
  hint?: string;
  error?: string | null;
  required?: boolean;
  /** Right-aligned micro text on the label row, e.g. "Optional" or a counter. */
  aside?: React.ReactNode;
  className?: string;
  children: React.ReactElement;
}

/**
 * Wraps a single control with its label, hint and error, and wires the ids so
 * screen readers announce all three. The control keeps its own props — Field
 * only fills in what it alone can know (the generated ids and invalid state).
 */
export function Field({
  label,
  hint,
  error,
  required,
  aside,
  className,
  children,
}: FieldProps) {
  const reactId = React.useId();
  const child = children as React.ReactElement<Record<string, unknown>>;
  const controlId = (child.props.id as string | undefined) ?? `field-${reactId}`;
  const hintId = hint ? `${controlId}-hint` : undefined;
  const errorId = error ? `${controlId}-error` : undefined;
  const describedBy = [errorId, hintId].filter(Boolean).join(" ") || undefined;

  return (
    <div className={cn("flex flex-col gap-2", className)}>
      <div className="flex items-baseline justify-between gap-3">
        <label
          htmlFor={controlId}
          className="text-[13px] font-semibold text-[var(--foreground)]"
        >
          {label}
          {required && <span className="ml-1 text-[var(--brand)]">*</span>}
        </label>
        {aside && (
          <span className="text-[12px] font-medium tabular-nums text-[var(--foreground-mute)]">
            {aside}
          </span>
        )}
      </div>

      {React.cloneElement(child, {
        id: controlId,
        "aria-describedby": describedBy,
        "aria-invalid": error ? true : undefined,
        "aria-required": required || undefined,
        className: cn(
          child.props.className as string | undefined,
          error &&
            "border-[var(--error)] focus-visible:border-[var(--error)] focus-visible:ring-[color-mix(in_srgb,var(--error)_18%,transparent)]"
        ),
      })}

      {error ? (
        <p
          id={errorId}
          role="alert"
          className="flex items-start gap-1.5 text-[12.5px] font-medium text-[var(--error)]"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" className="mt-px flex-none">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 8v5M12 16.5v.01" />
          </svg>
          {error}
        </p>
      ) : hint ? (
        <p id={hintId} className="text-[12.5px] text-[var(--foreground-mute)]">
          {hint}
        </p>
      ) : null}
    </div>
  );
}
