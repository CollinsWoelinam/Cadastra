import { NextResponse, type NextRequest } from "next/server";
import { chromium, type Browser } from "playwright";
import { ACCESS_COOKIE, fetchAsUser, setSessionCookies } from "@/lib/session";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// One browser per server process, reused across requests (and across dev reloads).
const globalForBrowser = globalThis as unknown as { certBrowser?: Promise<Browser> };

function browser(): Promise<Browser> {
  globalForBrowser.certBrowser ??= chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"] })
    .catch((e) => { globalForBrowser.certBrowser = undefined; throw e; });
  return globalForBrowser.certBrowser;
}

export async function GET(request: NextRequest, ctx: RouteContext<"/api/certificates/[id]">) {
  const { id } = await ctx.params;
  if (!UUID_RE.test(id)) return new Response("invalid parcel id", { status: 400 });

  const { res, refreshed, accessToken } = await fetchAsUser(request, `/parcels/${id}`);
  if (!res || res.status === 401 || !accessToken) return new Response("not authenticated", { status: 401 });
  if (res.status === 404) return new Response("parcel not found", { status: 404 });
  if (!res.ok) return new Response("core engine unavailable", { status: 502 });
  const parcel: { title_deed_no: string } = await res.json();

  const origin = process.env.CERT_RENDER_ORIGIN ?? request.nextUrl.origin;
  // The renderer gets only the short-lived access token. Handing it the refresh token
  // would let it rotate the session out from under the user's browser.
  const context = await (await browser()).newContext({
    // Lay the page out exactly as it will print (A4 minus 14 mm margins ≈ 688 CSS px) so the
    // map is fitted at its final size rather than resized by print CSS after rendering.
    viewport: { width: 688, height: 1000 },
  });
  await context.addCookies([{ name: ACCESS_COOKIE, value: accessToken, url: origin, httpOnly: true }]);
  const page = await context.newPage();
  try {
    await page.emulateMedia({ media: "print" });
    await page.goto(`${origin}/parcels/${id}/certificate`, { waitUntil: "load" });
    await page.waitForFunction(() => window.__certReady === true, null, { timeout: 30_000 });
    const pdf = await page.pdf({ format: "A4", printBackground: true });
    const filename = `certificate-${parcel.title_deed_no.replace(/[^A-Za-z0-9-]+/g, "_")}.pdf`;
    const out = new NextResponse(new Uint8Array(pdf), {
      headers: { "Content-Type": "application/pdf", "Content-Disposition": `attachment; filename="${filename}"` },
    });
    if (refreshed) setSessionCookies(out, refreshed);
    return out;
  } catch (e) {
    return new Response(`certificate rendering failed: ${(e as Error).message}`, { status: 500 });
  } finally {
    await context.close();
  }
}
