// MapLibre resolves its web worker relative to its own module URL, which breaks once
// the library is bundled. Serve the worker from public/ and point setWorkerUrl at it.
import { copyFileSync, mkdirSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";

const require = createRequire(import.meta.url);
const dist = dirname(require.resolve("maplibre-gl/package.json")) + "/dist";
mkdirSync("public/maplibre", { recursive: true });
copyFileSync(join(dist, "maplibre-gl-worker.mjs"), "public/maplibre/maplibre-gl-worker.mjs");
