import { NextResponse, type NextRequest } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/session";

// Sends visitors without a session to /login. This only checks that a session cookie
// exists; the API validates the token on every call.
export function proxy(request: NextRequest) {
  // The certificate renderer carries only an access cookie.
  if (request.cookies.has(REFRESH_COOKIE) || request.cookies.has(ACCESS_COOKIE)) return NextResponse.next();
  const login = new URL("/login", request.url);
  login.searchParams.set("next", request.nextUrl.pathname + request.nextUrl.search);
  return NextResponse.redirect(login);
}

export const config = {
  // Pages and the certificate PDF. /core answers 401 itself; static assets stay public.
  matcher: ["/((?!login|api/auth|core|_next|maplibre|favicon.ico).*)"],
};
