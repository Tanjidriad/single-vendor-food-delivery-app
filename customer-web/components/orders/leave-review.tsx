"use client";

import { useState } from "react";
import { Star } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useCreateReview } from "@/lib/api/queries/reviews";
import { ApiError } from "@/lib/api/client";

export function LeaveReview({ orderId }: { orderId: string }) {
  const create = useCreateReview();
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState("");
  const [done, setDone] = useState(false);
  const [hover, setHover] = useState(0);

  if (done) {
    return (
      <div className="mt-5 border-2 border-[var(--ink)] bg-[var(--surface)] p-5 text-center sm:p-6">
        <p className="font-street text-xl">Thanks for the review</p>
        <p className="mt-1 text-sm text-[var(--foreground-dim)]">
          Your feedback helps keep Wasabi sharp.
        </p>
      </div>
    );
  }

  return (
    <div className="mt-5 border-2 border-[var(--ink)] bg-[var(--surface)] p-5 sm:p-6">
      <h2 className="font-street text-xl">Rate this order</h2>
      <p className="mt-1 text-sm text-[var(--foreground-dim)]">
        How was everything?
      </p>

      <div className="mt-4 flex gap-1">
        {Array.from({ length: 5 }).map((_, i) => {
          const value = i + 1;
          const active = value <= (hover || rating);
          return (
            <button
              key={value}
              type="button"
              aria-label={`${value} stars`}
              onMouseEnter={() => setHover(value)}
              onMouseLeave={() => setHover(0)}
              onClick={() => setRating(value)}
              className="grid h-10 w-10 place-items-center transition-colors hover:bg-[var(--surface-sunken)]"
            >
              <Star
                className={`h-6 w-6 ${
                  active
                    ? "fill-[var(--mustard)] text-[var(--mustard)]"
                    : "text-[var(--border)]"
                }`}
              />
            </button>
          );
        })}
      </div>

      <textarea
        value={comment}
        onChange={(e) => setComment(e.target.value)}
        placeholder="Tell us more (optional)"
        rows={3}
        className="mt-4 w-full resize-none border border-[var(--border)] bg-[var(--background)] p-3 text-sm outline-none focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_16%,transparent)]"
      />

      <Button
        className="mt-4"
        disabled={create.isPending}
        onClick={() =>
          create.mutate(
            {
              orderId,
              rating,
              comment: comment.trim() || undefined,
            },
            {
              onSuccess: () => {
                setDone(true);
                toast.success("Review submitted.");
              },
              onError: (e) =>
                toast.error(
                  e instanceof ApiError ? e.message : "Couldn't submit review."
                ),
            }
          )
        }
      >
        {create.isPending ? "Sending…" : "Submit review"}
      </Button>
    </div>
  );
}
