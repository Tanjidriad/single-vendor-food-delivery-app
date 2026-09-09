"use client";

import { useEffect } from "react";
import { AlertTriangle } from "lucide-react";

import { Button } from "@/components/ui/button";

export default function ErrorPage({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    console.error("Customer page error", error);
  }, [error]);

  return (
    <main className="wasabi-app-shell grid min-h-[70dvh] place-items-center bg-[var(--menu-tan)] px-4 text-center">
      <div className="max-w-md">
        <AlertTriangle className="mx-auto h-12 w-12 text-[var(--brand)]" />
        <h1 className="font-street mt-5 text-4xl">Something went wrong</h1>
        <p className="mt-3 text-sm text-[var(--foreground-dim)]">Your basket and account are safe. Try loading this page again.</p>
        <Button size="lg" className="mt-7" onClick={reset}>Try again</Button>
      </div>
    </main>
  );
}
