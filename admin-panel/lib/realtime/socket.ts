"use client";

import { io, type Socket } from "socket.io-client";

const SOCKET_URL =
  process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3000";

let socket: Socket | null = null;

/** Lazily create (or reuse) the /realtime socket, authenticated with the JWT. */
export function getSocket(token: string | null): Socket {
  if (socket) {
    if (token && socket.auth && (socket.auth as { token?: string }).token !== token) {
      // Token rotated — reconnect with the new credential.
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

/** Server → client events the admin panel listens for. */
export const REALTIME_EVENTS = {
  orderCreated: "order:created",
  orderStatusChanged: "order:status.changed",
  assignmentCreated: "assignment:created",
  assignmentAccepted: "assignment:accepted",
  assignmentRejected: "assignment:rejected",
  assignmentExpired: "assignment:expired",
  riderLocation: "rider:location.updated",
} as const;
