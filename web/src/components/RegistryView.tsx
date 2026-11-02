"use client";

import { useEffect, useMemo, useState } from "react";
import type { Polygon } from "geojson";
import Link from "next/link";
import CadastraMap from "@/components/CadastraMap";
import { api, type Parcel, type ParcelEvent, type ParcelStatus, type RegistryEvent, type StatusCounts } from "@/lib/api";
import { formatAcres, formatDate, formatMetres, formatSqm, timeAgo } from "@/lib/format";
import { canReview, useMe } from "@/components/Session";
import { CheckIcon, DownloadIcon, SearchIcon } from "@/components/Icons";

const STATUS_LABEL: Record<ParcelStatus, string> = { APPROVED: "Approved", PENDING: "Pending", REJECTED: "Rejected" };
const EVENT_LABEL: Record<string, string> = { SUBMITTED: "Submitted", APPROVED: "Approved", REJECTED: "Rejected" };
const EVENT_DOT: Record<string, string> = { APPROVED: "dot-green", REJECTED: "dot-red" };
const TOGGLES: { status: ParcelStatus; swatch: string }[] = [
  { status: "APPROVED", swatch: "swatch-approved" },
  { status: "PENDING", swatch: "swatch-pending" },
  { status: "REJECTED", swatch: "swatch-rejected" },
];

function extentPolygon(b: [number, number, number, number]): Polygon {
  return { type: "Polygon", coordinates: [[[b[0], b[1]], [b[2], b[1]], [b[2], b[3]], [b[0], b[3]], [b[0], b[1]]]] };
}

export default function RegistryView() {
  const me = useMe();
  const [parcels, setParcels] = useState<Parcel[]>([]);
  const [stats, setStats] = useState<StatusCounts | null>(null);
  const [activity, setActivity] = useState<RegistryEvent[]>([]);
  const [fitTarget, setFitTarget] = useState<Polygon | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<{ parcel: Parcel; events: ParcelEvent[] } | null>(null);
  const [query, setQuery] = useState("");
  const [shown, setShown] = useState<ParcelStatus[]>(["APPROVED", "PENDING"]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.extent().then((b) => b && setFitTarget(extentPolygon(b))).catch(() => {});
    api.parcels().then(setParcels).catch(() => {});
    api.stats().then(setStats).catch(() => {});
    api.recentEvents(6).then(setActivity).catch(() => {});
  }, []);

  useEffect(() => {
    if (!selectedId) return;
    let cancelled = false;
    Promise.all([api.parcel(selectedId), api.events(selectedId)])
      .then(([parcel, events]) => !cancelled && (setDetail({ parcel, events: [...events].reverse() }), setError(null)))
      .catch((e) => !cancelled && setError(String(e.message)));
    return () => { cancelled = true; };
  }, [selectedId]);

  const matches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return [];
    return parcels
      .filter((p) => p.title_deed_no.toLowerCase().includes(q) || p.owner_name.toLowerCase().includes(q))
      .slice(0, 6);
  }, [parcels, query]);

  /** Select a parcel and bring it into view (from search or activity, not map clicks). */
  function focus(id: string) {
    setSelectedId(id);
    setQuery("");
    const p = parcels.find((x) => x.id === id);
    if (p) setFitTarget(p.boundary);
    else api.parcel(id).then((x) => setFitTarget(x.boundary)).catch(() => {});
  }

  function toggle(status: ParcelStatus) {
    setShown((s) => (s.includes(status) ? s.filter((x) => x !== status) : [...s, status]));
  }

  const parcel = detail?.parcel.id === selectedId ? detail.parcel : null;
  const events = parcel ? detail!.events : [];

  return (
    <div className="workspace">
      <aside className="side" aria-label="Parcel details">
        <form role="search" className="field" onSubmit={(e) => { e.preventDefault(); if (matches[0]) focus(matches[0].id); }}>
          <label htmlFor="q">Find a parcel</label>
          <div className="search-box">
            <SearchIcon color="#5A6862" />
            <input id="q" type="search" placeholder="Title deed or owner" value={query} autoComplete="off"
                   onChange={(e) => setQuery(e.target.value)} />
          </div>
          {query.trim() && (
            <ul className="search-results">
              {matches.length === 0 && <li className="muted" style={{ padding: "10px" }}>No parcel matches “{query.trim()}”.</li>}
              {matches.map((p) => (
                <li key={p.id}>
                  <button type="button" onClick={() => focus(p.id)}>
                    <span><span className="mono">{p.title_deed_no}</span><br /><span className="muted">{p.owner_name}</span></span>
                    <span className={`pill pill-${p.status}`}>{STATUS_LABEL[p.status]}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </form>

        <dl className="stat-grid">
          <div className="stat"><dt className="stat-label">Approved</dt><dd className="stat-value">{stats?.APPROVED ?? "–"}</dd></div>
          <div className="stat pending"><dt className="stat-label">Pending</dt><dd className="stat-value">{stats?.PENDING ?? "–"}</dd></div>
          <div className="stat"><dt className="stat-label">Rejected</dt><dd className="stat-value">{stats?.REJECTED ?? "–"}</dd></div>
        </dl>

        {error && <div className="alert">{error}</div>}
        {!parcel ? (
          <div className="card empty-card">Select a parcel on the map, or search for one, to see its record.</div>
        ) : (
          <section className="card parcel-card" aria-labelledby="sel-title">
            <div className="parcel-card-head">
              <div className="parcel-card-title">
                <h2 id="sel-title">{parcel.title_deed_no}</h2>
                <span className={`pill pill-${parcel.status}`}>
                  {parcel.status === "APPROVED" && <CheckIcon size={12} strokeWidth={3} />}{STATUS_LABEL[parcel.status]}
                </span>
              </div>
              <div className="parcel-owner">{parcel.owner_name}</div>
              {parcel.survey_accuracy_m != null && (
                <div className="muted">Corners surveyed to ±{parcel.survey_accuracy_m.toFixed(2)} m</div>
              )}
            </div>
            <dl className="parcel-measures">
              <div><dt>Area</dt><dd>{formatSqm(parcel.area_sqm)}</dd></div>
              <div><dt>Acres</dt><dd>{formatAcres(parcel.area_sqm)}</dd></div>
              <div><dt>Perimeter</dt><dd>{formatMetres(parcel.perimeter_m)}</dd></div>
            </dl>
            <ol className="timeline" aria-label="History">
              {events.map((e, i) => (
                <li key={i}>
                  <span className={`dot ${EVENT_DOT[e.event_type] ?? ""}`} />
                  <span>
                    <strong>{EVENT_LABEL[e.event_type] ?? e.event_type}</strong>
                    {e.actor_name && <> by {e.actor_name}</>} · {formatDate(e.at)}
                    {typeof e.detail?.note === "string" && e.detail.note && <><br /><span className="muted">“{e.detail.note}”</span></>}
                  </span>
                </li>
              ))}
            </ol>
            <div className="btn-row">
              {parcel.status === "PENDING" && canReview(me) ? (
                <Link className="btn btn-primary" href={`/inspector?id=${parcel.id}`}>Review survey</Link>
              ) : (
                <Link className="btn btn-primary" href={`/parcels/${parcel.id}/certificate`}>Survey plan</Link>
              )}
              <a className="btn" href={`/api/certificates/${parcel.id}`}><DownloadIcon size={16} />Certificate PDF</a>
            </div>
          </section>
        )}

        <section aria-labelledby="act-title" style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <h2 id="act-title" className="eyebrow">Recent activity</h2>
          {activity.length === 0 && <p className="muted" style={{ margin: 0 }}>Nothing recorded yet.</p>}
          <ul className="activity">
            {activity.map((e, i) => (
              <li key={i}>
                <button type="button" onClick={() => focus(e.parcel_id)}>
                  <span><span className="mono">{e.title_deed_no}</span> {(EVENT_LABEL[e.event_type] ?? e.event_type).toLowerCase()}
                    {e.actor_name && <> by {e.actor_name}</>}</span>
                  <time dateTime={e.at}>{timeAgo(e.at)}</time>
                </button>
              </li>
            ))}
          </ul>
        </section>
      </aside>

      <div className="map-pane">
        <CadastraMap highlight={parcel?.boundary} fitTo={fitTarget} fitMaxZoom={18.5} vertexLabels statuses={shown}
                     onParcelClick={(p) => setSelectedId(p.id)} />
        <div className="map-float map-toggles" role="group" aria-label="Show parcels">
          {TOGGLES.map(({ status, swatch }) => (
            <button key={status} type="button" className="toggle" aria-pressed={shown.includes(status)} onClick={() => toggle(status)}>
              <span className={`swatch ${swatch}`} style={{ width: 10, height: 10 }} />{STATUS_LABEL[status]}
            </button>
          ))}
        </div>
        <div className="map-float map-panel legend">
          <span><span className="swatch swatch-selected" />Selected parcel</span>
          <span><span className="swatch swatch-approved" />Approved</span>
          <span><span className="swatch swatch-pending" />Pending review</span>
        </div>
      </div>
    </div>
  );
}
