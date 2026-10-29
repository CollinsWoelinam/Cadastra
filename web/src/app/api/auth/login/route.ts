import { NextResponse, type NextRequest } from "next/server";
import { CORE_API_URL, setSessionCookies, type TokenPair } from "@/lib/session";

export async function POST(request: NextRequest) {
  const { email, password } = await request.json().catch(() => ({}));
  // Pass on the browser's address so the API throttles per client, not per portal server.
  const forwardedFor = request.headers.get("x-forwarded-for");
  const res = await fetch(`${CORE_API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(forwardedFor && { "X-Forwarded-For": forwardedFor }) },
    body: JSON.stringify({ email, password }),
    cache: "no-store",
  });
  if (res.status === 429) {
    const minutes = Math.ceil(Number(res.headers.get("retry-after") ?? 900) / 60);
    return NextResponse.json(
      { detail: `Too many sign-in attempts. Try again in ${minutes} minute${minutes === 1 ? "" : "s"}.` },
      { status: 429 },
    );
  }
  if (!res.ok) {
    const detail = res.status === 401 ? "Incorrect email or password." : "Sign-in is unavailable right now.";
    return NextResponse.json({ detail }, { status: res.status === 401 ? 401 : 502 });
  }
  const pair: TokenPair = await res.json();
  const out = NextResponse.json({ user: pair.user });
  setSessionCookies(out, pair);
  return out;
}
