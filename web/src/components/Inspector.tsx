"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import CadastraMap, { SUBJECT_COLOR } from "@/components/CadastraMap";
import { REGISTRY_CHANGED } from "@/components/AppHeader";
import { api, ApiError, SQFT_PER_SQM, type Conflict, type Parcel } from "@/lib/api";
import { formatAcres, formatDate, formatMetres, formatSqm, timeAgo } from "@/lib/format";
import { canReview, useMe } from "@/components/Session";
import { ArrowRightIcon, CheckCircleIcon, WarningIcon } from "@/components/Icons";

type QueueEntry = { parcel: Parcel; conflicts: Conflict[] };

function verdict(conflicts: Conflict[]) {
  if (conflicts.some((c) => c.blocking)) return { label: "Encroaches", cls: "pill-encroaches" };
  if (conflicts.length) return { label: "Overlap", cls: "pill-overlap" };
  return { label: "Clear", cls: "pill-clear" };
}

const lowerFirst = (s: string) => s.charAt(0).toLowerCase() + s.slice(1);

/** Pending surveys with their current conflicts. */
async function fetchQueue(): Promise<QueueEntry[]> {
  const pending = await api.parcels("PENDING");
  return Promise.all(pending.map(async (parcel) => ({ parcel, conflicts: await api.conflicts(parcel.id) })));
}

export default function Inspector() {
  const router = useRouter();
  const me = useMe();
  const selectedId = useSearchParams().get("id");
  const [queue, setQueue] = useState<QueueEntry[] | null>(null);
  // Keyed by survey, so switching surveys starts with an empty note.
  const [draft, setDraft] = useState<{ id: string | null; text: string }>({ id: null, text: "" });
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const [tileVersion, setTileVersion] = useState(0);

  const select = useCallback((id: string | null) => {
    router.replace(id ? `/inspector?id=${id}` : "/inspector", { scroll: false });
  }, [router]);

  const loadQueue = useCallback(async () => {
    const entries = await fetchQueue();
    setQueue(entries);
    return entries;
  }, []);

  useEffect(() => {
    let cancelled = false;
    fetchQueue().then((entries) => {
      if (cancelled) return;
      setQueue(entries);
      if (!selectedId && entries.length) select(entries[0].parcel.id);
    });
    return () => { cancelled = true; };
    // Only on mount; later reloads happen after review actions.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const note = draft.id === selectedId ? draft.text : "";
  const entry = queue?.find((e) => e.parcel.id === selectedId) ?? null;
  const parcel = entry?.parcel ?? null;
  const conflicts = entry?.conflicts ?? [];
  const blocking = conflicts.filter((c) => c.blocking);
  const ownSubmission = !!me && parcel?.submitted_by === me.id;
  const corners = parcel ? parcel.boundary.coordinates[0].length - 1 : 0;

  async function review(action: "approve" | "reject") {
    if (!parcel) return;
    setBusy(true);
    setMessage(null);
    try {
      await api[action](parcel.id, note);
      setMessage({ ok: true, text: `${parcel.title_deed_no} ${action === "approve" ? "approved" : "rejected"}.` });
      setTileVersion((v) => v + 1);
      window.dispatchEvent(new Event(REGISTRY_CHANGED));
      const entries = await loadQueue();
      select(entries[0]?.parcel.id ?? null);
    } catch (e) {
      setMessage({ ok: false, text: e instanceof ApiError ? e.message : String(e) });
      // Approval can be refused because another parcel was approved meanwhile.
      await loadQueue();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="workspace">
      <nav className="side narrow" aria-label="Review queue">
        <div className="queue-head">
          <h2>Awaiting review</h2>
          <span className="muted">{queue ? `${queue.length} survey${queue.length === 1 ? "" : "s"}` : "Loading…"}</span>
        </div>
        {queue?.length === 0 && <div className="card empty-card">Nothing is waiting for review.</div>}
        <ul className="queue">
          {queue?.map(({ parcel: p, conflicts: c }) => {
            const v = verdict(c);
            return (
              <li key={p.id}>
                <button type="button" className="queue-item" aria-current={p.id === selectedId ? "true" : undefined}
                        onClick={() => select(p.id)}>
                  <span className="queue-item-top"><span className="mono">{p.title_deed_no}</span><span className={`pill ${v.cls}`}>{v.label}</span></span>
                  <span>{p.owner_name}</span>
                  <span className="muted">{formatSqm(p.area_sqm)} · submitted {lowerFirst(timeAgo(p.created_at))}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="map-pane">
        <CadastraMap tileVersion={tileVersion} highlight={parcel?.boundary} highlightColor={SUBJECT_COLOR}
                     fitTo={parcel?.boundary} fitMaxZoom={19} conflicts={conflicts} vertexLabels
                     onParcelClick={(p) => p.status === "PENDING" && select(p.id)} />
        <div className="map-float map-panel legend inline">
          <span><span className="swatch swatch-subject" />Survey under review</span>
          <span><span className="swatch swatch-blocking" />Overlap · approved</span>
          <span><span className="swatch swatch-warning" />Overlap · pending</span>
        </div>
        {parcel && (
          <div className="map-float map-strip">
            <span><span>Corners</span> <strong>{corners}</strong></span>
            {parcel.survey_accuracy_m != null && <span><span>Worst accuracy</span> <strong>±{parcel.survey_accuracy_m.toFixed(2)} m</strong></span>}
          </div>
        )}
      </div>

      <aside className="side right" aria-label="Review decision">
        {message && <div className={`alert ${message.ok ? "alert-ok" : ""}`} role="status">{message.text}</div>}
        {!parcel ? (
          queue && <p className="muted">Select a survey from the queue.</p>
        ) : (
          <>
            <div className="decision-head">
              <span className="mono muted">{parcel.title_deed_no}</span>
              <h1>{parcel.owner_name}</h1>
              <span className="muted">
                {parcel.submitted_by_name ? `Surveyed by ${parcel.submitted_by_name} · ` : "Submitted "}{formatDate(parcel.created_at)}
              </span>
            </div>

            <dl className="facts">
              <div><dt>Area</dt><dd>{formatSqm(parcel.area_sqm)}</dd></div>
              <div><dt>Acres</dt><dd>{formatAcres(parcel.area_sqm)}</dd></div>
              <div><dt>Perimeter</dt><dd>{formatMetres(parcel.perimeter_m)}</dd></div>
            </dl>

            {blocking.length > 0 ? (
              <div className="alert" role="alert">
                <WarningIcon size={20} color="#B42318" />
                <div><strong>Encroaches on approved land.</strong> It overlaps{" "}
                  {blocking.length <= 2
                    ? blocking.map((c) => `${c.title_deed_no} by ${c.overlap_area_sqm.toFixed(2)} m²`).join(" and ")
                    : `${blocking.length} approved parcels`} and cannot be approved until the boundary is resurveyed.</div>
              </div>
            ) : conflicts.length === 0 ? (
              <div className="alert alert-ok"><CheckCircleIcon size={20} color="#0B6E4F" /><div><strong>No overlaps.</strong> The boundary does not overlap any registered or pending parcel.</div></div>
            ) : null}

            {conflicts.length > 0 && (
              <section aria-labelledby="conf" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                <h2 id="conf" className="eyebrow">Boundary conflicts · {conflicts.length}</h2>
                <div className="conflict-list">
                  {conflicts.map((c) => (
                    <div className="conflict-row" key={c.parcel_id}>
                      <span className={`conflict-key ${c.blocking ? "blocking" : ""}`} />
                      <span className="who"><span className="mono">{c.title_deed_no}</span><span className="muted">{c.owner_name} · {c.blocking ? "Approved" : "Pending"}</span></span>
                      <span className="how-much"><strong>{c.overlap_area_sqm.toFixed(2)} m²</strong><span className="muted">{(c.overlap_area_sqm * SQFT_PER_SQM).toFixed(1)} ft²</span></span>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {!canReview(me) ? (
              <p className="muted">Only reviewers can approve or reject surveys.</p>
            ) : ownSubmission ? (
              <p className="muted">You submitted this survey, so another reviewer must decide it.</p>
            ) : (
              <>
                <div className="field">
                  <label htmlFor="note">Review note</label>
                  <textarea id="note" className="textarea" rows={3} value={note} onChange={(e) => setDraft({ id: selectedId, text: e.target.value })}
                            placeholder="Recorded in the audit trail with your decision" />
                </div>
                <div className="btn-row">
                  <button type="button" className="btn btn-primary btn-lg" disabled={busy || blocking.length > 0}
                          onClick={() => review("approve")}>Approve</button>
                  <button type="button" className="btn btn-danger btn-lg" disabled={busy} onClick={() => review("reject")}>
                    {conflicts.length ? "Reject for resurvey" : "Reject"}
                  </button>
                </div>
              </>
            )}
            <Link href={`/parcels/${parcel.id}/certificate`} style={{ fontWeight: 600, display: "inline-flex", alignItems: "center", gap: 6 }}>
              Open survey plan <ArrowRightIcon size={14} />
            </Link>
          </>
        )}
      </aside>
    </div>
  );
}
