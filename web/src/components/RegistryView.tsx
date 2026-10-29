"use client";

import { useEffect, useState } from "react";
import type { Polygon } from "geojson";
import Link from "next/link";
import CadastraMap, { STATUS_COLORS } from "@/components/CadastraMap";
import { api, type Parcel, type ParcelStatus } from "@/lib/api";
import { AreaSummary } from "@/components/AreaSummary";

export default function RegistryView() {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [parcel, setParcel] = useState<Parcel | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [registryExtent, setRegistryExtent] = useState<Polygon | null>(null);

  useEffect(() => {
    api.extent().then((b) => b && setRegistryExtent({
      type: "Polygon",
      coordinates: [[[b[0], b[1]], [b[2], b[1]], [b[2], b[3]], [b[0], b[3]], [b[0], b[1]]]],
    }));
  }, []);

  useEffect(() => {
    if (!selectedId) return;
    let cancelled = false;
    api.parcel(selectedId)
      .then((p) => !cancelled && (setParcel(p), setError(null)))
      .catch((e) => !cancelled && setError(String(e.message)));
    return () => { cancelled = true; };
  }, [selectedId]);

  return (
    <div className="workspace">
      <aside className="sidebar">
        <h2>Registry map</h2>
        {!parcel && <p className="muted">Select a parcel on the map to view its record.</p>}
        {error && <div className="alert">{error}</div>}
        {parcel && (
          <>
            <dl className="props">
              <dt>Title deed</dt><dd><strong>{parcel.title_deed_no}</strong></dd>
              <dt>Owner</dt><dd>{parcel.owner_name}</dd>
              <dt>Status</dt><dd><span className={`badge ${parcel.status}`}>{parcel.status}</span></dd>
              <dt>Submitted</dt>
              <dd>
                {new Date(parcel.created_at).toLocaleString()}
                {parcel.submitted_by_name && <div className="muted">by {parcel.submitted_by_name}</div>}
              </dd>
              {parcel.reviewed_by_name && (
                <><dt>Reviewed by</dt><dd>{parcel.reviewed_by_name}</dd></>
              )}
              {parcel.survey_accuracy_m != null && (
                <><dt>Survey accuracy</dt><dd>±{parcel.survey_accuracy_m.toFixed(2)} m</dd></>
              )}
            </dl>
            <h3>Measurements</h3>
            <AreaSummary areaSqm={parcel.area_sqm} perimeterM={parcel.perimeter_m} />
            <div className="actions">
              {parcel.status === "PENDING" && (
                <Link className="btn" href={`/inspector?id=${parcel.id}`}>Inspect</Link>
              )}
              <Link className="btn" href={`/parcels/${parcel.id}/certificate`}>Certificate</Link>
            </div>
          </>
        )}
      </aside>
      <div className="map-wrap">
        <CadastraMap highlight={parcel?.boundary} fitTo={registryExtent} onParcelClick={(p) => setSelectedId(p.id)} />
        <div className="legend">
          {(Object.keys(STATUS_COLORS) as ParcelStatus[]).map((s) => (
            <span key={s}><span className="swatch" style={{ background: STATUS_COLORS[s] }} />{s}</span>
          ))}
        </div>
      </div>
    </div>
  );
}
