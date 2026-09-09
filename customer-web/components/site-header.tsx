"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { User } from "lucide-react";

import { Wordmark } from "@/components/brand";
import { ThemeToggle } from "@/components/theme-toggle";
import { useAuth } from "@/lib/auth/use-auth";
import { cn } from "@/lib/utils";

export function SiteHeader() {
  const { isAuthenticated, hydrated } = useAuth();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-[100] transition-[background-color,box-shadow,border-color] duration-300",
        scrolled
          ? "border-b border-[var(--border)] bg-[color-mix(in_srgb,var(--background)_88%,transparent)] shadow-[var(--shadow-xs)] backdrop-blur-md"
          : "border-b border-transparent bg-transparent"
      )}
    >
      <div className="mx-auto flex max-w-[1280px] items-center justify-between px-4 py-3.5 sm:px-6 lg:px-10">
        <Link href="/" aria-label="Wasabi home">
          <Wordmark />
        </Link>
        <nav className="flex items-center gap-2 sm:gap-3">
          <ThemeToggle />
          <Link
            href={hydrated && isAuthenticated ? "/account" : "/login"}
            className="flex items-center gap-1.5 rounded-full border border-[var(--border)] bg-[var(--surface)] px-4 py-2 text-sm font-semibold text-[var(--foreground)] transition-colors hover:bg-[var(--surface-sunken)]"
          >
            <User className="h-4 w-4" />
            <span className="hidden sm:inline">
              {hydrated && isAuthenticated ? "Account" : "Sign in"}
            </span>
          </Link>
        </nav>
      </div>
    </header>
  );
}
