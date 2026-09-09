"use client";

import { toast as sonner, Toaster as SonnerToaster } from "sonner";
import type { ReactNode } from "react";

/**
 * Branded snackbars. Sonner handles queueing, focus and timers; this layer owns
 * the look, so no call site hand-styles a toast.
 *
 * Always go through notify.* — sonner's own toast.success() paints its palette
 * over the brand and skips the icon block and the drain bar.
 */

type Tone = "success" | "error" | "warning" | "info";

const TONE: Record<Tone, { accent: string; icon: ReactNode }> = {
  success: {
    accent: "var(--success)",
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="square">
        <path d="M5 12.5l4.5 4.5L19 7.5" />
      </svg>
    ),
  },
  error: {
    accent: "var(--error)",
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
        <path d="M6 6l12 12M18 6L6 18" />
      </svg>
    ),
  },
  warning: {
    accent: "var(--warning)",
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6">
        <path d="M12 4l9 16H3z" />
        <path d="M12 10v4M12 17.5v.01" />
      </svg>
    ),
  },
  info: {
    accent: "var(--brand)",
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6">
        <circle cx="12" cy="12" r="9" />
        <path d="M12 11v5M12 7.5v.01" />
      </svg>
    ),
  },
};

interface Options {
  description?: ReactNode;
  /** One reversible follow-up — "Undo", "Track order". Never a second choice. */
  action?: { label: string; onClick: () => void };
  duration?: number;
}

function render(tone: Tone, message: ReactNode, opts: Options | undefined, duration: number) {
  const { accent, icon } = TONE[tone];
  return (
    <div
      className="pointer-events-auto relative flex w-full items-start gap-3 overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)] p-3.5 pr-4 shadow-[0_10px_30px_-8px_rgba(0,0,0,0.28)]"
      style={{ borderLeftWidth: 4, borderLeftColor: accent }}
    >
      <span
        aria-hidden
        className="mt-px grid h-6 w-6 flex-none place-items-center"
        style={{ color: accent }}
      >
        {icon}
      </span>

      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <p className="text-[13.5px] font-semibold leading-tight text-[var(--foreground)]">
          {message}
        </p>
        {opts?.description && (
          <p className="text-[12px] leading-snug text-[var(--foreground-mute)]">{opts.description}</p>
        )}
      </div>

      {opts?.action && (
        <button
          type="button"
          onClick={opts.action.onClick}
          className="ml-1 flex-none self-center rounded-lg border border-[var(--border)] px-3 py-1.5 text-[12px] font-semibold text-[var(--foreground)] transition-colors hover:bg-[var(--surface-sunken)]"
        >
          {opts.action.label}
        </button>
      )}

      {/* Shows the remaining time rather than making it a guess. */}
      <span
        aria-hidden
        className="toast-timer absolute bottom-0 left-0 h-[3px] w-full"
        style={{ background: accent, ["--toast-duration" as string]: `${duration}ms` }}
      />
    </div>
  );
}

function show(tone: Tone, message: ReactNode, opts?: Options) {
  const duration = opts?.duration ?? (tone === "error" ? 6000 : 4000);
  return sonner.custom(() => render(tone, message, opts, duration), { duration });
}

export const notify = {
  success: (message: ReactNode, opts?: Options) => show("success", message, opts),
  error: (message: ReactNode, opts?: Options) => show("error", message, opts),
  warning: (message: ReactNode, opts?: Options) => show("warning", message, opts),
  info: (message: ReactNode, opts?: Options) => show("info", message, opts),
  /** Ties a snackbar to a promise: pending, then settled, with no manual dismissal. */
  promise: <T,>(
    promise: Promise<T>,
    messages: { loading: string; success: string | ((value: T) => string); error: string }
  ) => sonner.promise(promise, messages),
  dismiss: sonner.dismiss,
};

/**
 * Top-centre. The bottom of the screen belongs to the cart bar and the mobile
 * tab bar, and a snackbar parked under the thumb pauses its own timer on hover.
 */
export function BrandToaster() {
  return (
    <SonnerToaster
      position="top-center"
      gap={10}
      toastOptions={{
        unstyled: true,
        classNames: {
          toast: "w-full",
          // Fallback shell for any sonner.promise / legacy toast() call site.
          default:
            "flex w-full items-center gap-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-3.5 text-[13.5px] font-medium text-[var(--foreground)] shadow-[0_10px_30px_-8px_rgba(0,0,0,0.28)]",
          loading:
            "flex w-full items-center gap-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-3.5 text-[13.5px] font-medium text-[var(--foreground)] shadow-[0_10px_30px_-8px_rgba(0,0,0,0.28)]",
          success:
            "flex w-full items-center gap-3 rounded-xl border border-l-4 border-[var(--border)] border-l-[var(--success)] bg-[var(--surface)] p-3.5 text-[13.5px] font-medium text-[var(--foreground)] shadow-[0_10px_30px_-8px_rgba(0,0,0,0.28)]",
          error:
            "flex w-full items-center gap-3 rounded-xl border border-l-4 border-[var(--border)] border-l-[var(--error)] bg-[var(--surface)] p-3.5 text-[13.5px] font-medium text-[var(--foreground)] shadow-[0_10px_30px_-8px_rgba(0,0,0,0.28)]",
        },
      }}
    />
  );
}
