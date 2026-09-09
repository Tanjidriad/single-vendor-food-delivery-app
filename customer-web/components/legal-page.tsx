import Link from "next/link";

import { Wordmark } from "@/components/brand";

export function LegalPage({
  title,
  updated,
  children,
}: {
  title: string;
  updated: string;
  children: React.ReactNode;
}) {
  return (
    <main className="wasabi-app-shell min-h-dvh bg-[var(--menu-rice)] px-4 py-8 sm:px-6 sm:py-12">
      <article className="mx-auto max-w-3xl border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-5 sm:p-10">
        <Link href="/" aria-label="Wasabi home">
          <Wordmark />
        </Link>
        <p className="wasabi-page-kicker mt-10">
          Customer information
        </p>
        <h1 className="font-street mt-4 text-4xl sm:text-6xl">{title}</h1>
        <p className="mt-2 text-sm text-[var(--foreground-mute)]">Last updated: {updated}</p>
        <div className="mt-8 space-y-7 text-sm leading-7 text-[var(--foreground-dim)] [&_h2]:font-display [&_h2]:text-xl [&_h2]:font-black [&_h2]:text-[var(--foreground)] [&_p]:mt-2 [&_ul]:mt-2 [&_ul]:list-disc [&_ul]:space-y-1 [&_ul]:pl-5">
          {children}
        </div>
        <div className="mt-10 flex flex-wrap gap-4 border-t border-[var(--border-subtle)] pt-6 text-sm font-semibold">
          <Link className="text-[var(--brand)] hover:underline" href="/support">Contact support</Link>
          <Link className="hover:underline" href="/">Back home</Link>
        </div>
      </article>
    </main>
  );
}
