import { useAuthStore } from "@/store/auth-store";

export const API_BASE_URL = "/api/backend";

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
  /** Kept for query-call compatibility; the BFF decides auth from HttpOnly cookies. */
  auth?: boolean;
  raw?: boolean;
}

async function request<T>(
  method: string,
  endpoint: string,
  options: RequestOptions = {}
): Promise<T> {
  const { raw = false, body, headers: extraHeaders, auth: _auth, ...rest } =
    options;
  void _auth;
  const headers = new Headers(extraHeaders);
  if (!raw && body !== undefined) headers.set("content-type", "application/json");
  headers.set("accept", "application/json");

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method,
    headers,
    body:
      body === undefined
        ? undefined
        : raw
          ? (body as BodyInit)
          : JSON.stringify(body),
    credentials: "same-origin",
    cache: "no-store",
    ...rest,
  });

  let data: unknown = null;
  const text = await response.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!response.ok) {
    if (response.status === 401) useAuthStore.getState().logout();
    const message =
      (data as { message?: string | string[] } | null)?.message ??
      "Request failed";
    throw new ApiError(
      response.status,
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
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    sp.set(key, String(value));
  }
  const result = sp.toString();
  return result ? `?${result}` : "";
}
