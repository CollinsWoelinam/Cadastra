"use client";

import type { Polygon } from "geojson";
import CadastraMap from "@/components/CadastraMap";

/** The certified boundary on the basemap, for anonymous visitors (no registry layer). */
export default function VerifyMap({ boundary }: { boundary: Polygon }) {
  return <CadastraMap highlight={boundary} fitTo={boundary} fitMaxZoom={18.5} vertexLabels showRegistry={false} interactive={false} />;
}
