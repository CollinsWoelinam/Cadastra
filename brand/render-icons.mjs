// Renders the app icons in web/ and mobile/ from the SVGs in this folder.
//   node brand/render-icons.mjs        (uses the portal's Playwright)
import { execFileSync } from "node:child_process";
import { copyFileSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "../web/node_modules/playwright/index.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const svg = (name) => readFileSync(join(root, "brand", name), "utf8");
const browser = await chromium.launch();

async function render(source, size, out, { transparent = false } = {}) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  const data = Buffer.from(source).toString("base64");
  await page.setContent(`<body style="margin:0"><img src="data:image/svg+xml;base64,${data}" width="${size}" height="${size}" style="display:block"></body>`);
  await page.locator("img").evaluate((img) => img.decode());
  await page.screenshot({ path: out, omitBackground: transparent });
  await page.close();
}

// Portal: SVG favicon and the Apple touch icon.
copyFileSync(join(root, "brand/app-icon-rounded.svg"), join(root, "web/src/app/icon.svg"));
await render(svg("app-icon.svg"), 180, join(root, "web/src/app/apple-icon.png"));

// iOS: every size in the asset catalogue, opaque (the App Store refuses icons with alpha).
const iosDir = join(root, "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset");
for (const file of readdirSync(iosDir).filter((f) => f.endsWith(".png"))) {
  const [, pt, scale] = file.match(/Icon-App-([\d.]+)x[\d.]+@(\d)x\.png/);
  const out = join(iosDir, file);
  await render(svg("app-icon.svg"), Math.round(Number(pt) * Number(scale)), out);
  execFileSync("sips", ["-s", "format", "jpeg", out, "--out", `${out}.jpg`], { stdio: "ignore" });
  execFileSync("sips", ["-s", "format", "png", `${out}.jpg`, "--out", out], { stdio: "ignore" });
  execFileSync("rm", [`${out}.jpg`]);
}

// Android legacy launcher icons, with their own rounded corners.
const densities = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
for (const [density, size] of Object.entries(densities)) {
  await render(svg("app-icon-rounded.svg"), size,
    join(root, `mobile/android/app/src/main/res/mipmap-${density}/ic_launcher.png`), { transparent: true });
}

await browser.close();
console.log("icons rendered");
