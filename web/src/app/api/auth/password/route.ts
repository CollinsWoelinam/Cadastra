import { NextResponse, type NextRequest } from "next/server";
import { detailMessage } from "@/lib/api";
import { clearSessionCookies, fetchAsUser, setSessionCookies, type TokenPair } from "@/lib/session";

// Changing the password ends every session, so the API returns a fresh token pair
// that must replace the browser's cookies; the generic /core proxy can't do that.
export async function POST(request: NextRequest) {
  const forwardedFor = request.headers.get("x-forwarded-for");
  const { res, refreshed } = await fetchAsUser(request, "/auth/password", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(forwardedFor && { "X-Forwarded-For": forwardedFor }) },
    body: await request.text(),
  });
  if (!res || res.status === 401) {
    const out = NextResponse.json({ detail: "Your session has ended. Sign in again." }, { status: 401 });
    clearSessionCookies(out);
    return out;
  }

  let out: NextResponse;
  if (res.ok) {
    const pair: TokenPair = await res.json();
    out = NextResponse.json({ ok: true });
    setSessionCookies(out, pair);
    return out;
  }
  if (res.status === 429) {
    const minutes = Math.ceil(Number(res.headers.get("retry-after") ?? 900) / 60);
    out = NextResponse.json(
      { detail: `Too many attempts. Try again in ${minutes} minute${minutes === 1 ? "" : "s"}.` },
      { status: 429 },
    );
  } else if (res.status === 400) {
    out = NextResponse.json({ detail: "Your current password is incorrect." }, { status: 400 });
  } else {
    const body = await res.json().catch(() => null);
    const detail = res.status < 500 ? detailMessage(body?.detail, "Could not change the password.") : null;
    out = NextResponse.json({ detail: detail ?? "The registry is unavailable right now." },
                            { status: res.status < 500 ? res.status : 502 });
  }
  if (refreshed) setSessionCookies(out, refreshed);
  return out;
}
