"use client";

import { io, type Socket } from "socket.io-client";

const SOCKET_URL =
  process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3000";

/** Give up reconnecting once the session itself is clearly gone. */
const MAX_AUTH_FAILURES = 3;

let socket: Socket | null = null;
let authFailures = 0;

/** Fetch a short-lived access token without exposing the refresh credential. */
export async function getRealtimeAccessToken(): Promise<string> {
  const response = await fetch("/api/auth/socket-token", {
    credentials: "same-origin",
    cache: "no-store",
  });
  if (!response.ok) throw new Error("Realtime authentication failed");
  const data = (await response.json()) as { accessToken?: string };
  if (!data.accessToken) throw new Error("Realtime token missing");
  return data.accessToken;
}

/**
 * Lazily create (or reuse) the authenticated /realtime socket.
 *
 * The access token lives 15 minutes while a delivery runs far longer, so the
 * token is resolved per connection attempt instead of being captured once:
 * Socket.IO invokes `auth` again on every reconnect, which is the
 * refresh-and-reconnect contract the gateway expects of its clients.
 */
export function connectRealtime(): Socket {
  if (socket) return socket;

  socket = io(`${SOCKET_URL}/realtime`, {
    auth: (cb: (data: Record<string, unknown>) => void) => {
      getRealtimeAccessToken()
        .then((token) => {
          authFailures = 0;
          cb({ token });
        })
        .catch(() => {
          authFailures += 1;
          if (authFailures >= MAX_AUTH_FAILURES) {
            // The session is gone, not the network — stop hammering the token
            // endpoint and let the next page load start a fresh socket.
            socket?.io.reconnection(false);
          }
          cb({});
        });
    },
    // Keep the polling fallback. Mobile networks that block or mangle the
    // WebSocket upgrade would otherwise get no live updates at all.
    transports: ["websocket", "polling"],
    autoConnect: true,
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 15000,
  });

  return socket;
}

export function disconnectSocket() {
  socket?.disconnect();
  socket = null;
  authFailures = 0;
}

/** Server → client events the customer app listens for. */
export const REALTIME_EVENTS = {
  orderStatusChanged: "order:status.changed",
  riderLocation: "rider:location.updated",
  orderDispatchedExternal: "order:dispatched.external",
} as const;
