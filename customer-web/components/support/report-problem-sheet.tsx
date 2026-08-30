"use client";

import { useEffect, useState } from "react";
import { X } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useCreateComplaint } from "@/lib/api/queries/complaints";
import { ApiError } from "@/lib/api/client";
import type { ComplaintType } from "@/types";

const TYPES: { value: ComplaintType; label: string; hint: string }[] = [
  { value: "COMPLAINT", label: "Something went wrong", hint: "Report an issue with your order" },
  { value: "REFUND_REQUEST", label: "Request a refund", hint: "Ask for money back" },
];

/**
 * Bottom sheet for raising a complaint or refund request against an order.
 * Mirrors the item-sheet treatment: slide-up on mobile, centered card on desktop.
 */
export function ReportProblemSheet({
  orderId,
  open,
  onClose,
}: {
  orderId: string;
  open: boolean;
  onClose: () => void;
}) {
  const create = useCreateComplaint();
  const [type, setType] = useState<ComplaintType>("COMPLAINT");
  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [refundAmount, setRefundAmount] = useState("");

  useEffect(() => {
    if (open) {
      setType("COMPLAINT");
      setSubject("");
      setDescription("");
      setRefundAmount("");
    }
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  const canSubmit =
    subject.trim().length > 0 && description.trim().length > 0 && !create.isPending;

  function submit() {
    const parsedRefund = Number(refundAmount);
    create.mutate(
      {
        orderId,
        type,
        subject: subject.trim(),
        description: description.trim(),
        refundAmount:
          type === "REFUND_REQUEST" && parsedRefund > 0 ? parsedRefund : undefined,
      },
      {
        onSuccess: () => {
          toast.success("We've received your report.");
          onClose();
        },
        onError: (e) =>
          toast.error(
            e instanceof ApiError ? e.message : "Couldn't submit your report."
          ),
      }
    );
  }

  return (
    <div className="fixed inset-0 z-[var(--z-drawer)] flex items-end justify-center sm:items-center sm:p-4">
      <button
        aria-label="Close"
        className="absolute inset-0 bg-black/50 backdrop-blur-[2px]"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="report-title"
        className="relative z-10 flex max-h-[90dvh] w-full max-w-lg flex-col overflow-hidden border-t-4 border-[var(--brand)] bg-[var(--surface)] shadow-[0_-8px_40px_rgba(24,22,21,0.2)] sm:border-2 sm:border-[var(--ink)]"
      >
        <div className="flex flex-none items-center justify-between border-b border-[var(--border-subtle)] px-5 py-4 sm:px-6">
          <h2 id="report-title" className="font-street text-xl">
            Counter support
          </h2>
          <button
            onClick={onClose}
            aria-label="Close"
            className="grid h-9 w-9 place-items-center bg-[var(--ink)] text-white transition-colors hover:bg-[var(--brand)]"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-5 sm:px-6">
          {/* Type toggle */}
          <div className="grid grid-cols-2 gap-2">
            {TYPES.map((t) => {
              const on = type === t.value;
              return (
                <button
                  key={t.value}
                  type="button"
                  onClick={() => setType(t.value)}
                  className={`border-2 p-3 text-left transition-colors ${
                    on
                      ? "border-[var(--brand)] bg-[color-mix(in_srgb,var(--brand)_6%,transparent)]"
                      : "border-[var(--border)] hover:border-[var(--foreground-mute)]"
                  }`}
                >
                  <span className="block text-sm font-bold">{t.label}</span>
                  <span className="mt-0.5 block text-[12px] text-[var(--foreground-dim)]">
                    {t.hint}
                  </span>
                </button>
              );
            })}
          </div>

          <div className="mt-5">
            <label
              htmlFor="report-subject"
              className="text-[11px] font-bold uppercase tracking-[0.16em] text-[var(--foreground-mute)]"
            >
              Subject
            </label>
            <input
              id="report-subject"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Missing item, late delivery…"
              className="mt-2 h-11 w-full border border-[var(--border)] bg-[var(--background)] px-3 text-sm outline-none focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_16%,transparent)]"
            />
          </div>

          <div className="mt-4">
            <label
              htmlFor="report-description"
              className="text-[11px] font-bold uppercase tracking-[0.16em] text-[var(--foreground-mute)]"
            >
              Details
            </label>
            <textarea
              id="report-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Tell us what happened so we can make it right."
              rows={4}
              className="mt-2 w-full resize-none border border-[var(--border)] bg-[var(--background)] p-3 text-sm outline-none focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_16%,transparent)]"
            />
          </div>

          {type === "REFUND_REQUEST" && (
            <div className="mt-4">
              <label
                htmlFor="report-refund"
                className="text-[11px] font-bold uppercase tracking-[0.16em] text-[var(--foreground-mute)]"
              >
                Refund amount (optional)
              </label>
              <input
                id="report-refund"
                type="number"
                inputMode="decimal"
                min={0}
                value={refundAmount}
                onChange={(e) => setRefundAmount(e.target.value)}
                placeholder="e.g. 250"
                className="mt-2 h-11 w-full border border-[var(--border)] bg-[var(--background)] px-3 text-sm tabular-nums outline-none focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_16%,transparent)]"
              />
            </div>
          )}
        </div>

        <div className="flex flex-none items-center gap-3 border-t border-[var(--border-subtle)] px-5 py-4 sm:px-6">
          <Button
            variant="ghost"
            className="flex-none"
            onClick={onClose}
          >
            Cancel
          </Button>
          <Button className="flex-1" size="lg" disabled={!canSubmit} onClick={submit}>
            {create.isPending ? "Sending…" : "Submit report"}
          </Button>
        </div>
      </div>
    </div>
  );
}
