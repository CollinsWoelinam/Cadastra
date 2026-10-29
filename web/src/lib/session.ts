// Server-only session handling. Tokens live in httpOnly cookies; browser code never
// sees them. The Next server attaches the access token when forwarding to the API.
import type { NextRequest, NextResponse } from "next/server";

export const CORE_API_URL = process.env.CORE_API_URL ?? "http://localhost:8000";
export const ACCESS_COOKIE = "cad_access";
export const REFRESH_COOKIE = "cad_refresh";

export interface SessionUser {
  id: string;
  email: string;
  full_name: string;
  role: "SURVEYOR" | "REVIEWER" | "ADMIN";
}

export interface TokenPair {
  access_token: string;
  access_expires_at: string;
  refresh_token: string;
  refresh_expires_at: string;
  user: SessionUser;
}

export function setSessionCookies(res: NextResponse, pair: TokenPair) {
  const base = { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax" as const, path: "/" };
  res.cookies.set(ACCESS_COOKIE, pair.access_token, { ...base, expires: new Date(pair.access_expires_at) });
  res.cookies.set(REFRESH_COOKIE, pair.refresh_token, { ...base, expires: new Date(pair.refresh_expires_at) });
}

export function clearSessionCookies(res: NextResponse) {
  res.cookies.delete(ACCESS_COOKIE);
  res.cookies.delete(REFRESH_COOKIE);
}

// Refresh tokens rotate on use and the API treats a replayed one as theft. The map
// fires many tile requests at once, so concurrent refreshes of the same token must
// share a single call. This is per server process: multi-instance deployments need
// sticky sessions.
const inflight = new Map<string, Promise<TokenPair | null>>();

export function refreshSession(refreshToken: string): Promise<TokenPair | null> {
  let pending = inflight.get(refreshToken);
  if (!pending) {
    pending = fetch(`${CORE_API_URL}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
      cache: "no-store",
    }).then((r) => (r.ok ? (r.json() as Promise<TokenPair>) : null));
    inflight.set(refreshToken, pending);
    // Keep the result briefly so stragglers carrying the old cookie get the same pair.
    pending.finally(() => setTimeout(() => inflight.delete(refreshToken), 30_000));
  }
  return pending;
}

/**
 * Calls the API as the signed-in user, refreshing the session once if needed.
 * `refreshed` is set when new cookies must be sent back to the browser.
 */
export async function fetchAsUser(
  request: NextRequest,
  path: string,
  init: RequestInit = {},
): Promise<{ res: Response | null; refreshed: TokenPair | null; accessToken: string | null }> {
  const send = (token: string) =>
    fetch(`${CORE_API_URL}${path}`, {
      ...init,
      headers: { ...init.headers, Authorization: `Bearer ${token}` },
      cache: "no-store",
    });

  const access = request.cookies.get(ACCESS_COOKIE)?.value;
  let res = access ? await send(access) : null;
  if (res && res.status !== 401) return { res, refreshed: null, accessToken: access! };

  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value;
  const refreshed = refreshToken ? await refreshSession(refreshToken) : null;
  if (!refreshed) return { res, refreshed: null, accessToken: null };
  res = await send(refreshed.access_token);
  return { res, refreshed, accessToken: refreshed.access_token };
}

/** Allows only same-site relative paths as post-login redirects. */
export function safeNextPath(next: string | null | undefined): string {
  return next && next.startsWith("/") && !next.startsWith("//") && !next.startsWith("/\\") ? next : "/";
}
