import type { NextRequest } from "next/server";
import { chromium, type Browser } from "playwright";

const CORE_API_URL = process.env.CORE_API_URL ?? "http://localhost:8000";
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

  const res = await fetch(`${CORE_API_URL}/parcels/${id}`, { cache: "no-store" });
  if (res.status === 404) return new Response("parcel not found", { status: 404 });
  if (!res.ok) return new Response("core engine unavailable", { status: 502 });
  const parcel: { title_deed_no: string } = await res.json();

  const origin = process.env.CERT_RENDER_ORIGIN ?? request.nextUrl.origin;
  // Lay the page out exactly as it will print (A4 minus 14 mm margins ≈ 688 CSS px) so the
  // map is fitted at its final size rather than resized by print CSS after rendering.
  const page = await (await browser()).newPage({ viewport: { width: 688, height: 1000 } });
  try {
    await page.emulateMedia({ media: "print" });
    await page.goto(`${origin}/parcels/${id}/certificate`, { waitUntil: "load" });
    await page.waitForFunction(() => window.__certReady === true, null, { timeout: 30_000 });
    const pdf = await page.pdf({ format: "A4", printBackground: true });
    const filename = `certificate-${parcel.title_deed_no.replace(/[^A-Za-z0-9-]+/g, "_")}.pdf`;
    return new Response(new Uint8Array(pdf), {
      headers: { "Content-Type": "application/pdf", "Content-Disposition": `attachment; filename="${filename}"` },
    });
  } catch (e) {
    return new Response(`certificate rendering failed: ${(e as Error).message}`, { status: 500 });
  } finally {
    await page.close();
  }
}
