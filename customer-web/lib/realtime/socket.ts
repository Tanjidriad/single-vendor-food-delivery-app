"use client";

import { io, type Socket } from "socket.io-client";

const SOCKET_URL =
  process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3000";

let socket: Socket | null = null;

/** Lazily create (or reuse) the /realtime socket, authenticated with the JWT. */
export function getSocket(token: string | null): Socket {
  if (socket) {
    if (
      token &&
      socket.auth &&
      (socket.auth as { token?: string }).token !== token
    ) {
      socket.auth = { token };
      socket.disconnect().connect();
    }
    return socket;
  }

  socket = io(`${SOCKET_URL}/realtime`, {
    auth: { token },
    transports: ["websocket"],
    autoConnect: true,
    reconnection: true,
    reconnectionDelay: 1000,
  });

  return socket;
}

export function disconnectSocket() {
  socket?.disconnect();
  socket = null;
}

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

/** Server → client events the customer app listens for. */
export const REALTIME_EVENTS = {
  orderStatusChanged: "order:status.changed",
  riderLocation: "rider:location.updated",
  orderDispatchedExternal: "order:dispatched.external",
} as const;
