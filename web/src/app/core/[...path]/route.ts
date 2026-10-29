import { NextResponse, type NextRequest } from "next/server";
import { clearSessionCookies, fetchAsUser, setSessionCookies } from "@/lib/session";

// Token-issuing endpoints are reachable only through /api/auth, which keeps the
// tokens in httpOnly cookies instead of handing them to page scripts.
const BLOCKED = new Set(["auth/login", "auth/refresh", "auth/logout"]);
const PASS_HEADERS = ["content-type", "content-disposition", "cache-control", "www-authenticate"];

async function forward(request: NextRequest, ctx: RouteContext<"/core/[...path]">) {
  const { path } = await ctx.params;
  const joined = path.join("/");
  if (BLOCKED.has(joined)) return NextResponse.json({ detail: "not found" }, { status: 404 });

  const hasBody = !["GET", "HEAD"].includes(request.method);
  const { res, refreshed } = await fetchAsUser(
    request,
    `/${path.map(encodeURIComponent).join("/")}${request.nextUrl.search}`,
    {
      method: request.method,
      headers: hasBody ? { "Content-Type": request.headers.get("content-type") ?? "application/json" } : {},
      body: hasBody ? await request.arrayBuffer() : undefined,
    },
  );

  if (!res) {
    const out = NextResponse.json({ detail: "not authenticated" }, { status: 401 });
    clearSessionCookies(out);
    return out;
  }
  const headers = new Headers();
  for (const h of PASS_HEADERS) {
    const v = res.headers.get(h);
    if (v) headers.set(h, v);
  }
  const out = new NextResponse(res.body, { status: res.status, headers });
  if (refreshed) setSessionCookies(out, refreshed);
  else if (res.status === 401) clearSessionCookies(out);
  return out;
}

export { forward as GET, forward as POST, forward as PATCH, forward as DELETE };
