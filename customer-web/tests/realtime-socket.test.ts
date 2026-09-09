import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type AuthCallback = (cb: (data: Record<string, unknown>) => void) => void;

const reconnection = vi.fn();
const disconnect = vi.fn();
type ConnectOptions = { transports: string[]; auth: AuthCallback };

const io = vi.fn(() => ({ io: { reconnection }, disconnect }));

vi.mock("socket.io-client", () => ({ io }));

/** Options the module handed to socket.io on the most recent connect. */
function lastOptions(): ConnectOptions {
  const call = io.mock.calls.at(-1) as unknown as [string, ConnectOptions] | undefined;
  if (!call) throw new Error("socket.io was never called");
  return call[1];
}

/** Drive the auth callback the way socket.io does on each connection attempt. */
function runAuth(): Promise<Record<string, unknown>> {
  return new Promise((resolve) => lastOptions().auth(resolve));
}

async function loadModule() {
  vi.resetModules();
  return import("../lib/realtime/socket");
}

describe("realtime socket", () => {
  beforeEach(() => {
    io.mockClear();
    reconnection.mockClear();
    disconnect.mockClear();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("keeps the polling fallback for networks that block the WebSocket upgrade", async () => {
    const { connectRealtime } = await loadModule();
    vi.stubGlobal("fetch", vi.fn());

    connectRealtime();

    expect(lastOptions().transports).toContain("polling");
    expect(lastOptions().transports).toContain("websocket");
  });

  it("resolves a fresh token on every connection attempt, not once per socket", async () => {
    const { connectRealtime } = await loadModule();
    let issued = 0;
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        json: async () => ({ accessToken: `token-${++issued}` }),
      }))
    );

    connectRealtime();

    // Two reconnects must not reuse the first (by then expired) access token.
    expect(await runAuth()).toEqual({ token: "token-1" });
    expect(await runAuth()).toEqual({ token: "token-2" });
  });

  it("stops reconnecting once the session is gone rather than looping forever", async () => {
    const { connectRealtime } = await loadModule();
    vi.stubGlobal("fetch", vi.fn(async () => ({ ok: false, json: async () => ({}) })));

    connectRealtime();

    await runAuth();
    await runAuth();
    expect(reconnection).not.toHaveBeenCalled();

    await runAuth();
    expect(reconnection).toHaveBeenCalledWith(false);
  });

  it("clears the failure count after a token succeeds again", async () => {
    const { connectRealtime } = await loadModule();
    let ok = false;
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok,
        json: async () => ({ accessToken: "token" }),
      }))
    );

    connectRealtime();

    await runAuth();
    await runAuth();
    ok = true;
    await runAuth();
    ok = false;
    await runAuth();
    await runAuth();

    // Only two consecutive failures since the success — still reconnecting.
    expect(reconnection).not.toHaveBeenCalled();
  });
});
