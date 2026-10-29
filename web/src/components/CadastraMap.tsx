"use client";

import { useEffect, useRef, useState } from "react";
import * as maplibregl from "maplibre-gl";
import {
  type GeoJSONSource,
  type LngLatBoundsLike,
  type Map as MLMap,
  type StyleSpecification,
  type VectorTileSource,
} from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import type { Feature, FeatureCollection, Geometry, Polygon, Position } from "geojson";
import type { Conflict, ParcelStatus } from "@/lib/api";

const BASEMAP_TILES = process.env.NEXT_PUBLIC_BASEMAP_TILES ?? "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
const BASEMAP_ATTRIBUTION =
  process.env.NEXT_PUBLIC_BASEMAP_ATTRIBUTION ?? "© OpenStreetMap contributors";
// East Legon, Accra.
const DEFAULT_CENTER: [number, number] = [-0.1525, 5.6305];

export const STATUS_COLORS: Record<ParcelStatus, string> = {
  APPROVED: "#2f9e6e",
  PENDING: "#e0a526",
  REJECTED: "#8a8f98",
};

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
  conflicts?: Conflict[];
  fitTo?: Polygon | null;
  vertexLabels?: boolean;
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

export default function CadastraMap({
  tileVersion = 0,
  highlight,
  conflicts,
  fitTo,
  vertexLabels,
  interactive = true,
  printable,
  onParcelClick,
  onReady,
  className,
}: Props) {
  const container = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MLMap | null>(null);
  const [loaded, setLoaded] = useState(false);
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
        parcels: { type: "vector", tiles: [tileUrl(tileVersion)], minzoom: 10, maxzoom: 20 },
        highlight: { type: "geojson", data: EMPTY },
        conflicts: { type: "geojson", data: EMPTY },
      },
      layers: [
        { id: "basemap", type: "raster", source: "basemap" },
        {
          id: "parcels-fill",
          type: "fill",
          source: "parcels",
          "source-layer": "parcels",
          paint: {
            "fill-color": ["match", ["get", "status"],
              "APPROVED", STATUS_COLORS.APPROVED, "PENDING", STATUS_COLORS.PENDING, STATUS_COLORS.REJECTED],
            "fill-opacity": 0.28,
          },
        },
        {
          id: "parcels-line",
          type: "line",
          source: "parcels",
          "source-layer": "parcels",
          paint: {
            "line-color": ["match", ["get", "status"],
              "APPROVED", STATUS_COLORS.APPROVED, "PENDING", STATUS_COLORS.PENDING, STATUS_COLORS.REJECTED],
            "line-width": 1.2,
          },
        },
        {
          id: "highlight-line",
          type: "line",
          source: "highlight",
          paint: { "line-color": "#1d4ed8", "line-width": 3 },
        },
        {
          id: "conflicts-fill",
          type: "fill",
          source: "conflicts",
          paint: { "fill-color": "#dc2626", "fill-opacity": ["case", ["get", "blocking"], 0.65, 0.35] },
        },
        {
          id: "conflicts-line",
          type: "line",
          source: "conflicts",
          paint: { "line-color": "#991b1b", "line-width": 1.5 },
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
    if (interactive) map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");
    map.addControl(new maplibregl.ScaleControl({ unit: "metric" }), "bottom-left");

    map.on("load", () => setLoaded(true));
    map.on("click", "parcels-fill", (e) => {
      const props = e.features?.[0]?.properties as TileParcel | undefined;
      if (props) onClickRef.current?.(props);
    });
    map.on("mouseenter", "parcels-fill", () => (map.getCanvas().style.cursor = "pointer"));
    map.on("mouseleave", "parcels-fill", () => (map.getCanvas().style.cursor = ""));

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
    if (!loaded) return;
    (mapRef.current!.getSource("parcels") as VectorTileSource).setTiles([tileUrl(tileVersion)]);
  }, [loaded, tileVersion]);

  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map) return;
    (map.getSource("highlight") as GeoJSONSource).setData(
      highlight ? { type: "FeatureCollection", features: [feature(highlight)] } : EMPTY,
    );
    (map.getSource("conflicts") as GeoJSONSource).setData({
      type: "FeatureCollection",
      features: (conflicts ?? []).map((c) => feature(c.overlap_geometry, { blocking: c.blocking })),
    });

    const markers = vertexLabels && highlight
      ? highlight.coordinates[0].slice(0, -1).map((pos, i) => {
          const el = document.createElement("div");
          el.className = "vertex-marker";
          el.textContent = String(i + 1);
          return new maplibregl.Marker({ element: el }).setLngLat(pos as [number, number]).addTo(map);
        })
      : [];
    return () => markers.forEach((m) => m.remove());
  }, [loaded, highlight, conflicts, vertexLabels]);

  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map) return;
    if (fitTo) {
      map.fitBounds(bounds(fitTo), { padding: 70, maxZoom: 20, animate: !printable && hasFitRef.current });
      hasFitRef.current = true;
    }
    map.once("idle", () => onReadyRef.current?.());
  }, [loaded, fitTo, printable]);

  return <div ref={container} className={className ?? "map"} />;
}
