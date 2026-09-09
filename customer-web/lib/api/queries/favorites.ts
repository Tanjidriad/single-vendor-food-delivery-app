"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuth } from "@/lib/auth/use-auth";
import type { Favorite } from "@/types";

/** The customer's saved dishes. */
export function useFavorites() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["favorites"],
    enabled: isAuthenticated,
    queryFn: () => api.get<Favorite[]>(endpoints.favorites.list),
  });
}

/** Lightweight set of favourited menu-item ids for quick lookups in lists. */
export function useFavoriteIds() {
  const { data } = useFavorites();
  return new Set((data ?? []).map((f) => f.menuItem.id));
}

export function useAddFavorite() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (menuItemId: string) =>
      api.post<Favorite>(endpoints.favorites.add(menuItemId)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["favorites"] }),
  });
}

export function useRemoveFavorite() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (menuItemId: string) =>
      api.delete(endpoints.favorites.remove(menuItemId)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["favorites"] }),
  });
}
