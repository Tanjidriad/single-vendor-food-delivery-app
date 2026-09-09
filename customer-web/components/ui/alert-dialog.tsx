"use client";

import * as React from "react";
import * as Dialog from "@radix-ui/react-dialog";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/feedback";
import { cn } from "@/lib/utils";

export interface AlertDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  /** Uppercase micro-line above the title, e.g. "Order #WSB-2043". */
  eyebrow?: string;
  description?: React.ReactNode;
  /** "danger" for anything that destroys or cancels something already paid for. */
  tone?: "default" | "danger";
  confirmLabel?: string;
  cancelLabel?: string;
  /**
   * Return a promise to keep the button pending until it settles. Any return
   * value is accepted so a handler can forward a toast id straight through.
   */
  onConfirm: () => unknown;
  children?: React.ReactNode;
}

/**
 * Blocking confirm for a single decision. Cancel holds focus, so a stray Enter
 * can never confirm a destructive action, and the dialog refuses to close while
 * the confirm is still in flight.
 */
export function AlertDialog({
  open,
  onOpenChange,
  title,
  eyebrow,
  description,
  tone = "default",
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  onConfirm,
  children,
}: AlertDialogProps) {
  const [pending, setPending] = React.useState(false);
  const cancelRef = React.useRef<HTMLButtonElement>(null);
  const accent = tone === "danger" ? "var(--error)" : "var(--brand)";

  async function handleConfirm() {
    try {
      setPending(true);
      await onConfirm();
      onOpenChange(false);
    } finally {
      setPending(false);
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={pending ? undefined : onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay
          className={cn(
            "fixed inset-0 z-[var(--z-overlay)] bg-[color-mix(in_srgb,var(--ink)_74%,transparent)] backdrop-blur-[3px]",
            "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:duration-200",
            "data-[state=closed]:animate-out data-[state=closed]:fade-out-0"
          )}
        />
        <Dialog.Content
          onOpenAutoFocus={(e) => {
            e.preventDefault();
            cancelRef.current?.focus();
          }}
          className={cn(
            "fixed left-1/2 top-1/2 z-[var(--z-modal)] w-[calc(100vw-2rem)] max-w-[420px] overflow-hidden",
            "-translate-x-1/2 -translate-y-1/2 rounded-2xl border border-[var(--border)] bg-[var(--surface)]",
            "shadow-[0_24px_60px_-12px_rgba(0,0,0,0.35)]",
            "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 data-[state=open]:duration-200 data-[state=open]:ease-out",
            "data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95"
          )}
        >
          {/* Full-bleed accent rule: the tone is legible before a word is read. */}
          <div aria-hidden className="h-1 w-full" style={{ background: accent }} />

          <div className="p-6 sm:p-7">
            {eyebrow && (
              <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--foreground-mute)]">
                {eyebrow}
              </p>
            )}

            <Dialog.Title className="text-[19px] font-bold leading-snug tracking-[-0.01em] text-[var(--foreground)]">
              {title}
            </Dialog.Title>

            {description && (
              <Dialog.Description className="mt-2 text-[13.5px] leading-relaxed text-[var(--foreground-dim)]">
                {description}
              </Dialog.Description>
            )}

            {children && <div className="mt-5">{children}</div>}

            <div className="mt-7 flex flex-col-reverse gap-2.5 sm:flex-row sm:justify-end">
              <Dialog.Close asChild>
                <Button ref={cancelRef} variant="light" size="sm" className="rounded-lg" disabled={pending}>
                  {cancelLabel}
                </Button>
              </Dialog.Close>
              <Button
                size="sm"
                onClick={handleConfirm}
                disabled={pending}
                className={cn("rounded-lg", tone === "danger" && "bg-[var(--error)] hover:bg-[var(--error)]")}
              >
                {pending && <Spinner className="h-4 w-4" />}
                {confirmLabel}
              </Button>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
