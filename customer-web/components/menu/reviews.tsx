"use client";

import { useState } from "react";
import { Star, ChevronLeft, ChevronRight } from "lucide-react";

import { useReviews } from "@/lib/api/queries/menu";
import type { Review } from "@/types";

function formatDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

export function Reviews() {
  const { data, isLoading } = useReviews();
  const reviews = data ?? [];
  const [i, setI] = useState(0);

  // Nothing to show until real, verified reviews exist.
  if (isLoading || reviews.length === 0) return null;

  const count = reviews.length;
  const avg = reviews.reduce((sum, r) => sum + r.rating, 0) / count;
  const shift = (d: number) => setI((p) => (p + d + count) % count);
  const visible = Array.from({ length: Math.min(3, count) }).map(
    (_, k) => reviews[(i + k) % count]
  );

  return (
    <section className="mx-auto max-w-[1440px] px-4 pt-10 sm:px-6 sm:pt-16 lg:px-10">
      <div className="mb-4 flex flex-wrap items-end justify-between gap-4 sm:mb-6 sm:gap-5">
        <div className="flex flex-wrap items-center gap-3 sm:gap-5">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[var(--brand)]">
              Reviews
            </p>
            <h2 className="mt-1.5 font-display text-[clamp(1.35rem,3.5vw,2.4rem)] font-black tracking-[-0.03em] sm:mt-2">
              What people are saying
            </h2>
          </div>
          {/* Rating summary — integrated into the header */}
          <div className="flex items-center gap-2.5 rounded-[12px] border border-[var(--border-subtle)] bg-[var(--surface)] px-3 py-2 sm:gap-3 sm:px-4 sm:py-3">
            <span className="font-display text-2xl font-black leading-none sm:text-3xl">
              {avg.toFixed(1)}
            </span>
            <div>
              <div className="flex gap-0.5">
                {Array.from({ length: 5 }).map((_, s) => (
                  <Star
                    key={s}
                    className={`h-3.5 w-3.5 ${
                      s < Math.round(avg)
                        ? "fill-[var(--mustard)] text-[var(--mustard)]"
                        : "text-[var(--border)]"
                    }`}
                  />
                ))}
              </div>
              <p className="mt-0.5 text-xs text-[var(--foreground-mute)]">
                {count} {count === 1 ? "review" : "reviews"}
              </p>
            </div>
          </div>
        </div>

        {count > 3 && (
          <div className="flex gap-2">
            <button
              onClick={() => shift(-1)}
              aria-label="Previous review"
              className="grid h-10 w-10 place-items-center rounded-full border border-[var(--border)] bg-[var(--surface)] transition-colors hover:border-[var(--brand)] hover:text-[var(--brand)]"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <button
              onClick={() => shift(1)}
              aria-label="Next review"
              className="grid h-10 w-10 place-items-center rounded-full border border-[var(--border)] bg-[var(--surface)] transition-colors hover:border-[var(--brand)] hover:text-[var(--brand)]"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </div>
        )}
      </div>

      <div className="-mx-4 flex snap-x snap-mandatory gap-3 overflow-x-auto px-4 pb-1 [scrollbar-width:none] md:mx-0 md:grid md:grid-cols-3 md:gap-4 md:overflow-visible md:px-0 md:pb-0 [&::-webkit-scrollbar]:hidden">
        {visible.map((r, k) => (
          <div key={`${r.id}-${k}`} className="w-[78vw] max-w-[280px] flex-none snap-start md:w-auto md:max-w-none">
            <ReviewCard review={r} />
          </div>
        ))}
      </div>
    </section>
  );
}

function ReviewCard({ review }: { review: Review }) {
  return (
    <article className="rounded-[12px] border border-[var(--border)] bg-[var(--surface)] p-6">
      <div className="flex items-center gap-3">
        <span className="grid h-11 w-11 place-items-center rounded-full bg-[var(--brand)]/10 font-display font-black text-[var(--brand)]">
          {review.authorName.trim()[0]?.toUpperCase() ?? "W"}
        </span>
        <div>
          <p className="font-bold leading-tight">{review.authorName}</p>
          <p className="text-xs text-[var(--foreground-mute)]">
            {formatDate(review.createdAt)}
          </p>
        </div>
      </div>
      <div className="mt-3 flex gap-0.5">
        {Array.from({ length: 5 }).map((_, s) => (
          <Star
            key={s}
            className={`h-4 w-4 ${
              s < review.rating
                ? "fill-[var(--mustard)] text-[var(--mustard)]"
                : "text-[var(--border)]"
            }`}
          />
        ))}
      </div>
      {review.comment && (
        <p className="mt-3 text-sm leading-relaxed text-[var(--foreground-dim)]">
          {review.comment}
        </p>
      )}
    </article>
  );
}
