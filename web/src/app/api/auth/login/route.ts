import { NextResponse, type NextRequest } from "next/server";
import { CORE_API_URL, setSessionCookies, type TokenPair } from "@/lib/session";

export async function POST(request: NextRequest) {
  const { email, password } = await request.json().catch(() => ({}));
  const res = await fetch(`${CORE_API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
    cache: "no-store",
  });
  if (!res.ok) {
    const detail = res.status === 401 ? "Incorrect email or password." : "Sign-in is unavailable right now.";
    return NextResponse.json({ detail }, { status: res.status === 401 ? 401 : 502 });
  }
  const pair: TokenPair = await res.json();
  const out = NextResponse.json({ user: pair.user });
  setSessionCookies(out, pair);
  return out;
}
