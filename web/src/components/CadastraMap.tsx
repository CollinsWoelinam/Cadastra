"use client";

import { useEffect, useRef, useState } from "react";
import * as maplibregl from "maplibre-gl";
import {
  type ExpressionSpecification,
  type GeoJSONSource,
  type LngLatBoundsLike,
  type Map as MLMap,
  type StyleSpecification,
  type VectorTileSource,
} from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import type { Feature, FeatureCollection, Geometry, Polygon, Position } from "geojson";
import type { Conflict, ParcelStatus } from "@/lib/api";
import { formatSqm } from "@/lib/format";
import { FitIcon, MinusIcon, PlusIcon } from "@/components/Icons";

const BASEMAP_TILES = process.env.NEXT_PUBLIC_BASEMAP_TILES || "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
const BASEMAP_ATTRIBUTION =
  process.env.NEXT_PUBLIC_BASEMAP_ATTRIBUTION || "© OpenStreetMap contributors";
// East Legon, Accra.
const DEFAULT_CENTER: [number, number] = [-0.1525, 5.6305];
const ALL_STATUSES: ParcelStatus[] = ["APPROVED", "PENDING", "REJECTED"];

/** Map colours per parcel status: fill, outline. */
export const STATUS_STYLE: Record<ParcelStatus, { fill: string; line: string }> = {
  APPROVED: { fill: "#DDE8E2", line: "#4B6158" },
  PENDING: { fill: "#FCEFD3", line: "#B7791F" },
  REJECTED: { fill: "#E6E6E6", line: "#8A8F98" },
};
export const SELECTED_COLOR = "#0B6E4F";
export const SUBJECT_COLOR = "#1D4ED8";

export interface TileParcel {
  id: string;
  title_deed_no: string;
  owner_name: string;
  status: ParcelStatus;
  area_sqm: number;
}

interface Props {
  /** Bump to refetch parcel tiles after a status change. */
  tileVersion?: number;
  highlight?: Polygon | null;
  /** Outline colour of the highlighted parcel: green for a selection, blue for a survey under review. */
  highlightColor?: string;
  conflicts?: Conflict[];
  fitTo?: Polygon | null;
  vertexLabels?: boolean;
  /** Closest zoom when fitting; lower keeps neighbouring parcels in view. */
  fitMaxZoom?: number;
  /** Draws registered parcels from the (signed-in) tile service; off for public pages. */
  showRegistry?: boolean;
  /** Parcel statuses drawn from the registry layer. */
  statuses?: ParcelStatus[];
  interactive?: boolean;
  /** Keeps the WebGL canvas readable for printing. */
  printable?: boolean;
  onParcelClick?: (parcel: TileParcel) => void;
  /** Fires once the map has rendered everything for the current fit. */
  onReady?: () => void;
  className?: string;
}

if (typeof window !== "undefined") {
  maplibregl.setWorkerUrl(`/maplibre/maplibre-gl-worker.mjs?v=${maplibregl.getVersion()}`);
}

const EMPTY: FeatureCollection = { type: "FeatureCollection", features: [] };

function tileUrl(version: number) {
  return `${window.location.origin}/core/tiles/{z}/{x}/{y}.mvt?v=${version}`;
}

function bounds(geom: Polygon): LngLatBoundsLike {
  const pts: Position[] = geom.coordinates.flat();
  const lons = pts.map((p) => p[0]);
  const lats = pts.map((p) => p[1]);
  return [Math.min(...lons), Math.min(...lats), Math.max(...lons), Math.max(...lats)];
}

function feature(geometry: Geometry, properties: Record<string, unknown> = {}): Feature {
  return { type: "Feature", geometry, properties };
}

function byStatus(key: "fill" | "line"): ExpressionSpecification {
  return ["match", ["get", "status"],
    "APPROVED", STATUS_STYLE.APPROVED[key], "PENDING", STATUS_STYLE.PENDING[key], STATUS_STYLE.REJECTED[key]];
}

/** Diagonal hatching for overlap areas, drawn once per map at device resolution. */
function hatch(color: string, alpha: number) {
  const size = 16;
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext("2d")!;
  ctx.fillStyle = color;
  ctx.globalAlpha = alpha;
  ctx.fillRect(0, 0, size, size);
  ctx.globalAlpha = 1;
  ctx.strokeStyle = color;
  ctx.lineWidth = 3;
  for (const o of [-size, 0, size]) {
    ctx.beginPath();
    ctx.moveTo(o, size);
    ctx.lineTo(o + size, 0);
    ctx.stroke();
  }
  return ctx.getImageData(0, 0, size, size);
}

// Registered parcels from the tile service; approved outlines solid, the rest dashed.
const REGISTRY_LAYERS: StyleSpecification["layers"] = [
  {
    id: "parcels-fill",
    type: "fill",
    source: "parcels",
    "source-layer": "parcels",
    paint: { "fill-color": byStatus("fill"), "fill-opacity": 0.6 },
  },
  {
    id: "parcels-line",
    type: "line",
    source: "parcels",
    "source-layer": "parcels",
    filter: ["==", ["get", "status"], "APPROVED"],
    paint: { "line-color": byStatus("line"), "line-width": 1.3 },
  },
  {
    id: "parcels-line-dashed",
    type: "line",
    source: "parcels",
    "source-layer": "parcels",
    filter: ["!=", ["get", "status"], "APPROVED"],
    paint: { "line-color": byStatus("line"), "line-width": 1.6, "line-dasharray": [3, 2] },
  },
];

export default function CadastraMap({
  tileVersion = 0,
  highlight,
  highlightColor = SELECTED_COLOR,
  conflicts,
  fitTo,
  vertexLabels,
  fitMaxZoom: maxZoom = 20,
  statuses = ALL_STATUSES,
  showRegistry = true,
  interactive = true,
  printable,
  onParcelClick,
  onReady,
  className,
}: Props) {
  const container = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MLMap | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [hover, setHover] = useState<{ x: number; y: number; parcel: TileParcel } | null>(null);
  // The first fit jumps into place; later ones (new selection) animate.
  const hasFitRef = useRef(false);
  const onClickRef = useRef(onParcelClick);
  const onReadyRef = useRef(onReady);
  useEffect(() => {
    onClickRef.current = onParcelClick;
    onReadyRef.current = onReady;
  });

  useEffect(() => {
    const style: StyleSpecification = {
      version: 8,
      sources: {
        basemap: {
          type: "raster",
          tiles: [BASEMAP_TILES],
          tileSize: 256,
          maxzoom: 19,
          attribution: BASEMAP_ATTRIBUTION,
        },
        ...(showRegistry && {
          parcels: { type: "vector" as const, tiles: [tileUrl(tileVersion)], minzoom: 10, maxzoom: 20 },
        }),
        highlight: { type: "geojson", data: EMPTY },
        conflicts: { type: "geojson", data: EMPTY },
      },
      layers: [
        { id: "basemap", type: "raster", source: "basemap" },
        ...(showRegistry ? REGISTRY_LAYERS : []),
        {
          id: "highlight-fill",
          type: "fill",
          source: "highlight",
          paint: { "fill-color": highlightColor, "fill-opacity": 0.18 },
        },
        {
          id: "highlight-line",
          type: "line",
          source: "highlight",
          paint: { "line-color": highlightColor, "line-width": 3.5 },
        },
        {
          id: "conflicts-fill",
          type: "fill",
          source: "conflicts",
          paint: { "fill-pattern": ["case", ["get", "blocking"], "hatch-blocking", "hatch-warning"] },
        },
        {
          id: "conflicts-line",
          type: "line",
          source: "conflicts",
          paint: { "line-color": ["case", ["get", "blocking"], "#B42318", "#B7791F"], "line-width": 2 },
        },
      ],
    };

    const map = new maplibregl.Map({
      container: container.current!,
      style,
      center: DEFAULT_CENTER,
      zoom: 16,
      maxZoom: 22,
      interactive,
      attributionControl: { compact: false },
      canvasContextAttributes: { preserveDrawingBuffer: !!printable },
      fadeDuration: printable ? 0 : 300,
    });
    map.addControl(new maplibregl.ScaleControl({ unit: "metric" }), "bottom-right");

    map.on("load", () => {
      // Conflicts start empty, so nothing asks for these patterns before they exist.
      map.addImage("hatch-blocking", hatch("#B42318", 0.3));
      map.addImage("hatch-warning", hatch("#B7791F", 0.3));
      setLoaded(true);
    });
    if (showRegistry) map.on("click", "parcels-fill", (e) => {
      const props = e.features?.[0]?.properties as TileParcel | undefined;
      if (props) onClickRef.current?.(props);
    });
    if (interactive && showRegistry) {
      map.on("mousemove", "parcels-fill", (e) => {
        map.getCanvas().style.cursor = "pointer";
        const props = e.features?.[0]?.properties as TileParcel | undefined;
        setHover(props ? { x: e.point.x, y: e.point.y, parcel: props } : null);
      });
      map.on("mouseleave", "parcels-fill", () => {
        map.getCanvas().style.cursor = "";
        setHover(null);
      });
    }

    mapRef.current = map;
    return () => {
      map.remove();
      mapRef.current = null;
      hasFitRef.current = false;
      setLoaded(false);
    };
    // The map is created once; later prop changes are applied by the effects below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!loaded || !showRegistry) return;
    (mapRef.current!.getSource("parcels") as VectorTileSource).setTiles([tileUrl(tileVersion)]);
  }, [loaded, tileVersion, showRegistry]);

  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map || !showRegistry) return;
    const shown: ExpressionSpecification = ["in", ["get", "status"], ["literal", statuses]];
    map.setFilter("parcels-fill", shown);
    map.setFilter("parcels-line", ["all", shown, ["==", ["get", "status"], "APPROVED"]]);
    map.setFilter("parcels-line-dashed", ["all", shown, ["!=", ["get", "status"], "APPROVED"]]);
  }, [loaded, statuses, showRegistry]);

  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map) return;
    map.setPaintProperty("highlight-fill", "fill-color", highlightColor);
    map.setPaintProperty("highlight-line", "line-color", highlightColor);
    (map.getSource("highlight") as GeoJSONSource).setData(
      highlight ? { type: "FeatureCollection", features: [feature(highlight)] } : EMPTY,
    );
    (map.getSource("conflicts") as GeoJSONSource).setData({
      type: "FeatureCollection",
      features: (conflicts ?? []).map((c) => feature(c.overlap_geometry, { blocking: c.blocking })),
    });

    const filled = highlightColor !== SELECTED_COLOR;
    const markers = vertexLabels && highlight
      ? highlight.coordinates[0].slice(0, -1).map((pos, i) => {
          const el = document.createElement("div");
          el.className = filled ? "vertex-marker filled" : "vertex-marker";
          el.style.setProperty("--vertex", highlightColor);
          el.textContent = String(i + 1);
          return new maplibregl.Marker({ element: el }).setLngLat(pos as [number, number]).addTo(map);
        })
      : [];
    return () => markers.forEach((m) => m.remove());
  }, [loaded, highlight, highlightColor, conflicts, vertexLabels]);

  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map) return;
    if (fitTo) {
      map.fitBounds(bounds(fitTo), { padding: 80, maxZoom, animate: !printable && hasFitRef.current });
      hasFitRef.current = true;
    }
    map.once("idle", () => onReadyRef.current?.());
  }, [loaded, fitTo, printable, maxZoom]);

  return (
    <div className={className ?? "cadastra-map"}>
      <div ref={container} style={{ position: "absolute", inset: 0 }} />
      {interactive && (
        <div className="map-float map-panel map-controls">
          <button type="button" aria-label="Zoom in" onClick={() => mapRef.current?.zoomIn()}><PlusIcon /></button>
          <button type="button" aria-label="Zoom out" onClick={() => mapRef.current?.zoomOut()}><MinusIcon /></button>
          <button type="button" aria-label="Fit to view" disabled={!fitTo}
                  onClick={() => fitTo && mapRef.current?.fitBounds(bounds(fitTo), { padding: 80, maxZoom })}>
            <FitIcon />
          </button>
        </div>
      )}
      {hover && (
        <div className="map-tooltip" style={{ left: hover.x, top: hover.y }}>
          <span className="mono">{hover.parcel.title_deed_no}</span>
          <span className="sub">{hover.parcel.owner_name} · {formatSqm(Number(hover.parcel.area_sqm))}</span>
        </div>
      )}
    </div>
  );
}
