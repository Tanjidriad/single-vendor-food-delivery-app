import { useAuthStore } from "@/store/auth-store";

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

export class ApiError extends Error {
  status: number;
  data: unknown;
  constructor(status: number, message: string, data?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.data = data;
  }
}

interface RequestOptions extends Omit<RequestInit, "body"> {
  body?: unknown;
  auth?: boolean;
  /** Skip JSON serialization (e.g. FormData uploads). */
  raw?: boolean;
}

// Single-flight refresh: concurrent 401s share one refresh promise.
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  const { refreshToken, setAccessToken, logout } = useAuthStore.getState();
  if (!refreshToken) {
    logout();
    return null;
  }
  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken }),
        });
        if (!res.ok) {
          logout();
          return null;
        }
        const data = await res.json();
        const token = data.accessToken ?? data.access_token;
        if (!token) {
          logout();
          return null;
        }
        setAccessToken(token);
        return token as string;
      } catch {
        logout();
        return null;
      } finally {
        refreshPromise = null;
      }
    })();
  }
  return refreshPromise;
}

async function request<T>(
  method: string,
  endpoint: string,
  options: RequestOptions = {}
): Promise<T> {
  const { auth = true, raw = false, body, headers: extraHeaders, ...rest } = options;

  const buildHeaders = (token: string | null): HeadersInit => {
    const h = new Headers(extraHeaders);
    if (!raw && body !== undefined) h.set("Content-Type", "application/json");
    if (auth && token) h.set("Authorization", `Bearer ${token}`);
    return h;
  };

  const exec = async (token: string | null): Promise<Response> => {
    return fetch(`${API_BASE_URL}${endpoint}`, {
      method,
      headers: buildHeaders(token),
      body:
        body === undefined
          ? undefined
          : raw
            ? (body as BodyInit)
            : JSON.stringify(body),
      ...rest,
    });
  };

  let token = auth ? useAuthStore.getState().accessToken : null;
  let res = await exec(token);

  // Transparent refresh on 401, retry once.
  if (res.status === 401 && auth) {
    const newToken = await refreshAccessToken();
    if (newToken) {
      token = newToken;
      res = await exec(newToken);
    }
  }

  let data: unknown = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!res.ok) {
    if (res.status === 401) useAuthStore.getState().logout();
    const message =
      (data as { message?: string | string[] })?.message ?? "Request failed";
    throw new ApiError(
      res.status,
      Array.isArray(message) ? message.join(", ") : message,
      data
    );
  }

  return data as T;
}

export const api = {
  get: <T>(endpoint: string, options?: RequestOptions) =>
    request<T>("GET", endpoint, options),
  post: <T>(endpoint: string, body?: unknown, options?: RequestOptions) =>
    request<T>("POST", endpoint, { ...options, body }),
  patch: <T>(endpoint: string, body?: unknown, options?: RequestOptions) =>
    request<T>("PATCH", endpoint, { ...options, body }),
  put: <T>(endpoint: string, body?: unknown, options?: RequestOptions) =>
    request<T>("PUT", endpoint, { ...options, body }),
  delete: <T>(endpoint: string, options?: RequestOptions) =>
    request<T>("DELETE", endpoint, options),
};

/** Build a query string from a params object, omitting empty values. */
export function qs(params: Record<string, unknown>): string {
  const sp = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null || v === "") continue;
    sp.set(k, String(v));
  }
  const s = sp.toString();
  return s ? `?${s}` : "";
}
