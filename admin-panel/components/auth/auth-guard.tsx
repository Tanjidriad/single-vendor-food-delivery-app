"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

import { FullPageSpinner } from "@/components/common/spinner";
import { useAuth } from "@/lib/auth/use-auth";

/** Client-side guard: waits for store hydration, then redirects unauthenticated users to /login. */
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { isAuthenticated, hydrated } = useAuth();

  useEffect(() => {
    if (hydrated && !isAuthenticated) {
      router.replace("/login");
    }
  }, [hydrated, isAuthenticated, router]);

  if (!hydrated || !isAuthenticated) {
    return <FullPageSpinner />;
  }

  return <>{children}</>;
}
