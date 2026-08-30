"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuth } from "@/lib/auth/use-auth";
import type { AppNotification } from "@/types";

/** The customer's notification inbox. Polls so the bell badge stays fresh. */
export function useNotifications() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["notifications"],
    enabled: isAuthenticated,
    queryFn: () => api.get<AppNotification[]>(endpoints.notifications.list),
    refetchInterval: 60000,
  });
}

/** Count of unread notifications for the nav bell badge. */
export function useUnreadCount() {
  const { data } = useNotifications();
  return (data ?? []).filter((n) => !n.readAt).length;
}

export function useMarkNotificationRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      api.patch<AppNotification>(endpoints.notifications.markRead(id)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["notifications"] }),
  });
}
