import Link from "next/link";
import { SearchX } from "lucide-react";

import { Wordmark } from "@/components/brand";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <main className="wasabi-app-shell grid min-h-dvh place-items-center bg-[var(--menu-red)] px-4 text-center text-white">
      <div className="max-w-md">
        <Wordmark className="justify-center" />
        <SearchX className="mx-auto mt-10 h-12 w-12 text-[var(--brand)]" />
        <h1 className="font-street mt-5 text-4xl sm:text-6xl">This page isn&apos;t on the menu</h1>
        <p className="mt-3 text-sm text-white/70">The link may be old, or the page may have moved.</p>
        <Button asChild size="lg" className="mt-7"><Link href="/menu">Browse the menu</Link></Button>
      </div>
    </main>
  );
}
