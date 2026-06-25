"use client";

import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

import { getSocket, REALTIME_EVENTS } from "@/lib/realtime/socket";
import { useAuthStore } from "@/store/auth-store";

/**
 * Subscribes to live order/dispatch events and invalidates the relevant
 * TanStack queries so dashboard, orders, and operations stay fresh without
 * manual refetching. Mounted once near the top of the authenticated app.
 */
export function useRealtimeSync() {
  const queryClient = useQueryClient();
  const token = useAuthStore((s) => s.accessToken);

  useEffect(() => {
    if (!token) return;
    const socket = getSocket(token);

    const invalidate = () => {
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["orders"] });
      queryClient.invalidateQueries({ queryKey: ["ops"] });
    };

    const events = Object.values(REALTIME_EVENTS).filter(
      (e) => e !== REALTIME_EVENTS.riderLocation
    );
    events.forEach((evt) => socket.on(evt, invalidate));

    return () => {
      events.forEach((evt) => socket.off(evt, invalidate));
    };
  }, [token, queryClient]);
}

/** Returns the live connection status for a small indicator in the UI. */
export function useRealtimeStatus() {
  const token = useAuthStore((s) => s.accessToken);
  useEffect(() => {
    if (token) getSocket(token);
  }, [token]);
}
