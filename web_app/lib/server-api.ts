import "server-only";
import { API_BASE } from "./api";
import { getAccessToken } from "./session";

export type ApiResult<T> =
  | { ok: true; data: T; status: number }
  | { ok: false; status: number; message: string };

type Opts = {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  body?: unknown;
  form?: FormData;
  /** Send the signed-in user's token (default true). */
  auth?: boolean;
};

/** FastAPI reports problems as { detail: string } or { detail: [{ msg, loc }] }. */
function messageFrom(body: unknown, status: number): string {
  const detail = (body as { detail?: unknown } | null)?.detail;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail) && detail.length > 0) {
    const first = detail[0] as { msg?: string; loc?: (string | number)[] };
    const field = first.loc?.filter((x): x is string => typeof x === "string" && x !== "body").pop();
    const msg = (first.msg ?? "Invalid value").replace(/^Value error, /, "");
    return field ? `${field.replace(/_/g, " ")}: ${msg}` : msg;
  }
  if (status === 401) return "Your session has ended. Sign in again.";
  if (status === 403) return "You don't have permission to do that.";
  if (status === 429) return "Too many attempts. Wait a minute and try again.";
  return "Something went wrong. Try again in a moment.";
}

/** Authenticated call to the MySun API. Never cached. */
export async function api<T = unknown>(path: string, opts: Opts = {}): Promise<ApiResult<T>> {
  const headers: Record<string, string> = {};
  if (opts.auth !== false) {
    const token = await getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }
  let body: BodyInit | undefined;
  if (opts.form) body = opts.form;
  else if (opts.body !== undefined) {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify(opts.body);
  }
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: opts.method ?? "GET",
      headers,
      body,
      cache: "no-store",
    });
    const text = await res.text();
    let json: unknown = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }
    if (!res.ok) return { ok: false, status: res.status, message: messageFrom(json, res.status) };
    return { ok: true, data: json as T, status: res.status };
  } catch {
    return {
      ok: false,
      status: 0,
      message: "Can't reach the MySun server. Check your connection and try again.",
    };
  }
}

/** Convenience: the data, or null when the call failed. */
export async function apiData<T>(path: string, opts?: Opts): Promise<T | null> {
  const r = await api<T>(path, opts);
  return r.ok ? r.data : null;
}
