import { NextResponse, type NextRequest } from "next/server";
import { clearSessionCookies, CORE_API_URL, REFRESH_COOKIE } from "@/lib/session";

export async function POST(request: NextRequest) {
  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value;
  if (refreshToken) {
    await fetch(`${CORE_API_URL}/auth/logout`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
      cache: "no-store",
    }).catch(() => undefined);
  }
  const out = new NextResponse(null, { status: 204 });
  clearSessionCookies(out);
  return out;
}
