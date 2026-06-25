"use client";

import { useState } from "react";
import {
  QueryClient,
  QueryClientProvider,
  type DefaultOptions,
} from "@tanstack/react-query";

import { ApiError } from "@/lib/api/client";

const defaultOptions: DefaultOptions = {
  queries: {
    staleTime: 30_000,
    refetchOnWindowFocus: false,
    retry: (failureCount, error) => {
      // Don't retry auth/permission errors.
      if (error instanceof ApiError && [401, 403, 404].includes(error.status)) {
        return false;
      }
      return failureCount < 2;
    },
  },
};

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [client] = useState(() => new QueryClient({ defaultOptions }));
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
}
