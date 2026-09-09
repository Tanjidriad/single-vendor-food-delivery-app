import { NextRequest, NextResponse } from "next/server";
import { isIP } from "node:net";

const ACCESS_COOKIE = "wasabi_access";
const REFRESH_COOKIE = "wasabi_refresh";
const ACCESS_MAX_AGE_SECONDS = 15 * 60;
const REFRESH_MAX_AGE_SECONDS = 7 * 24 * 60 * 60;

interface BackendSession {
  accessToken: string;
  refreshToken: string;
  user?: Record<string, unknown>;
}

function backendBaseUrl(): string {
  const configured =
    process.env.BACKEND_API_URL ??
    process.env.NEXT_PUBLIC_API_URL ??
    "http://localhost:3000/api/v1";
  const url = new URL(configured);
  if (!['http:', 'https:'].includes(url.protocol)) {
    throw new Error("BACKEND_API_URL must use http or https");
  }
  return url.toString().replace(/\/$/, "");
}

function cookieOptions(maxAge: number) {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax" as const,
    path: "/",
    maxAge,
  };
}

export function applySessionCookies(
  response: NextResponse,
  session: BackendSession
) {
  response.cookies.set(
    ACCESS_COOKIE,
    session.accessToken,
    cookieOptions(ACCESS_MAX_AGE_SECONDS)
  );
  response.cookies.set(
    REFRESH_COOKIE,
    session.refreshToken,
    cookieOptions(REFRESH_MAX_AGE_SECONDS)
  );
}

export function clearSessionCookies(response: NextResponse) {
  response.cookies.set(ACCESS_COOKIE, "", cookieOptions(0));
  response.cookies.set(REFRESH_COOKIE, "", cookieOptions(0));
}

function isBackendSession(value: unknown): value is BackendSession {
  if (!value || typeof value !== "object") return false;
  const session = value as Partial<BackendSession>;
  return (
    typeof session.accessToken === "string" &&
    typeof session.refreshToken === "string"
  );
}

function responseMessage(data: unknown, fallback: string): string {
  const message = (data as { message?: string | string[] } | null)?.message;
  if (Array.isArray(message)) return message.join(", ");
  return typeof message === "string" ? message : fallback;
}

async function parseBackendResponse(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function safeBackendPath(segments: string[]): string {
  if (
    segments.length === 0 ||
    segments.some(
      (segment) =>
        !segment || segment === "." || segment === ".." || /[\\/\0]/.test(segment)
    )
  ) {
    throw new Error("Invalid backend path");
  }
  return segments.map(encodeURIComponent).join("/");
}

function isStateChanging(method: string): boolean {
  return !["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase());
}

function hasValidRequestOrigin(request: NextRequest): boolean {
  if (!isStateChanging(request.method)) return true;

  const fetchSite = request.headers.get("sec-fetch-site");
  if (fetchSite && !["same-origin", "same-site", "none"].includes(fetchSite)) {
    return false;
  }

  const origin = request.headers.get("origin");
  if (!origin) return !!fetchSite;

  try {
    const allowedOrigins = new Set([request.nextUrl.origin]);
    if (process.env.NEXT_PUBLIC_SITE_URL) {
      allowedOrigins.add(new URL(process.env.NEXT_PUBLIC_SITE_URL).origin);
    }
    return allowedOrigins.has(new URL(origin).origin);
  } catch {
    return false;
  }
}

function forwardedHeaders(request: NextRequest, accessToken?: string): Headers {
  const headers = new Headers();
  const contentType = request.headers.get("content-type");
  const accept = request.headers.get("accept");
  const idempotencyKey = request.headers.get("idempotency-key");
  const forwardedChain = request.headers.get("x-forwarded-for");
  const clientIp =
    request.headers.get("x-real-ip") ??
    forwardedChain?.split(",").at(-1)?.trim();
  if (contentType) headers.set("content-type", contentType);
  if (accept) headers.set("accept", accept);
  if (idempotencyKey) headers.set("idempotency-key", idempotencyKey);
  if (clientIp && isIP(clientIp)) headers.set("x-forwarded-for", clientIp);
  if (accessToken) headers.set("authorization", `Bearer ${accessToken}`);
  return headers;
}

async function refreshSession(refreshToken: string): Promise<BackendSession | null> {
  const response = await fetch(`${backendBaseUrl()}/auth/refresh`, {
    method: "POST",
    headers: { "content-type": "application/json", accept: "application/json" },
    body: JSON.stringify({ refreshToken }),
    cache: "no-store",
  });
  const data = await parseBackendResponse(response);
  return response.ok && isBackendSession(data) ? data : null;
}

async function backendFetch(
  request: NextRequest,
  path: string,
  body: ArrayBuffer | undefined,
  accessToken?: string
) {
  return fetch(`${backendBaseUrl()}/${path}${request.nextUrl.search}`, {
    method: request.method,
    headers: forwardedHeaders(request, accessToken),
    body: body && body.byteLength > 0 ? body : undefined,
    cache: "no-store",
    redirect: "manual",
  });
}

function jsonResponse(data: unknown, status: number): NextResponse {
  return NextResponse.json(data, {
    status,
    headers: { "cache-control": "no-store" },
  });
}

const SESSION_ISSUING_PATHS = new Set([
  "auth/login",
  "auth/register",
  "auth/otp/verify",
  "auth/refresh",
]);

export async function proxyBackendRequest(
  request: NextRequest,
  segments: string[]
): Promise<NextResponse> {
  if (!hasValidRequestOrigin(request)) {
    return jsonResponse({ message: "Invalid request origin" }, 403);
  }

  let path: string;
  try {
    path = safeBackendPath(segments);
  } catch {
    return jsonResponse({ message: "Invalid backend path" }, 400);
  }

  const accessToken = request.cookies.get(ACCESS_COOKIE)?.value;
  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value;

  if (path === "auth/logout") {
    if (accessToken && refreshToken) {
      let logoutAccessToken = accessToken;
      let logoutRefreshToken = refreshToken;
      let logoutResponse = await fetch(`${backendBaseUrl()}/auth/logout`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${logoutAccessToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ refreshToken: logoutRefreshToken }),
        cache: "no-store",
      }).catch(() => null);
      if (logoutResponse?.status === 401) {
        const rotated = await refreshSession(refreshToken).catch(() => null);
        if (rotated) {
          logoutAccessToken = rotated.accessToken;
          logoutRefreshToken = rotated.refreshToken;
          logoutResponse = await fetch(`${backendBaseUrl()}/auth/logout`, {
            method: "POST",
            headers: {
              authorization: `Bearer ${logoutAccessToken}`,
              "content-type": "application/json",
            },
            body: JSON.stringify({ refreshToken: logoutRefreshToken }),
            cache: "no-store",
          }).catch(() => null);
        }
      }
    }
    const response = jsonResponse({ success: true }, 200);
    clearSessionCookies(response);
    return response;
  }

  const body = isStateChanging(request.method)
    ? await request.arrayBuffer()
    : undefined;
  let backendResponse = await backendFetch(
    request,
    path,
    body,
    accessToken
  );
  let refreshedSession: BackendSession | null = null;

  if (backendResponse.status === 401 && refreshToken) {
    refreshedSession = await refreshSession(refreshToken);
    if (refreshedSession) {
      backendResponse = await backendFetch(
        request,
        path,
        body,
        refreshedSession.accessToken
      );
    }
  }

  const data = await parseBackendResponse(backendResponse);
  if (!backendResponse.ok) {
    const response = jsonResponse(
      { message: responseMessage(data, "Request failed") },
      backendResponse.status
    );
    if (backendResponse.status === 401) clearSessionCookies(response);
    return response;
  }

  if (SESSION_ISSUING_PATHS.has(path) && isBackendSession(data)) {
    const response = jsonResponse({ user: data.user ?? null }, backendResponse.status);
    applySessionCookies(response, data);
    return response;
  }

  const response = jsonResponse(data, backendResponse.status);
  if (refreshedSession) applySessionCookies(response, refreshedSession);
  return response;
}

export async function socketTokenResponse(
  request: NextRequest
): Promise<NextResponse> {
  const accessToken = request.cookies.get(ACCESS_COOKIE)?.value;
  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value;

  if (accessToken) {
    const check = await fetch(`${backendBaseUrl()}/users/me`, {
      headers: { authorization: `Bearer ${accessToken}` },
      cache: "no-store",
    });
    if (check.ok) return jsonResponse({ accessToken }, 200);
  }

  if (refreshToken) {
    const session = await refreshSession(refreshToken);
    if (session) {
      const response = jsonResponse({ accessToken: session.accessToken }, 200);
      applySessionCookies(response, session);
      return response;
    }
  }

  const response = jsonResponse({ message: "Authentication required" }, 401);
  clearSessionCookies(response);
  return response;
}
