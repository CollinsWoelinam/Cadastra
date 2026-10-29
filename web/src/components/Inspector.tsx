"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import CadastraMap from "@/components/CadastraMap";
import { AreaSummary } from "@/components/AreaSummary";
import { api, ApiError, SQFT_PER_SQM, type Conflict, type Parcel } from "@/lib/api";

export default function Inspector() {
  const router = useRouter();
  const selectedId = useSearchParams().get("id");
  const [queue, setQueue] = useState<Parcel[]>([]);
  // Keyed by id so a stale selection is never shown while the next one loads.
  const [detail, setDetail] = useState<{ parcel: Parcel; conflicts: Conflict[] } | null>(null);
  const parcel = detail?.parcel.id === selectedId ? detail.parcel : null;
  const conflicts = parcel ? detail!.conflicts : [];
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const [tileVersion, setTileVersion] = useState(0);

  const select = useCallback((id: string | null) => {
    router.replace(id ? `/inspector?id=${id}` : "/inspector", { scroll: false });
  }, [router]);

  const loadQueue = useCallback(async () => {
    const pending = await api.parcels("PENDING");
    setQueue(pending);
    return pending;
  }, []);

  useEffect(() => {
    api.parcels("PENDING").then((pending) => {
      setQueue(pending);
      if (!selectedId && pending.length) select(pending[0].id);
    });
    // Only on mount; later reloads happen after review actions.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!selectedId) return;
    let cancelled = false;
    Promise.all([api.parcel(selectedId), api.conflicts(selectedId)]).then(([p, c]) => {
      if (cancelled) return;
      setDetail({ parcel: p, conflicts: c });
      setNote("");
    });
    return () => { cancelled = true; };
  }, [selectedId]);

  async function review(action: "approve" | "reject") {
    if (!parcel) return;
    setBusy(true);
    setMessage(null);
    try {
      await api[action](parcel.id, note);
      setMessage({ ok: true, text: `${parcel.title_deed_no} ${action === "approve" ? "approved" : "rejected"}.` });
      setTileVersion((v) => v + 1);
      const pending = await loadQueue();
      select(pending[0]?.id ?? null);
    } catch (e) {
      setMessage({ ok: false, text: e instanceof ApiError ? e.message : String(e) });
      // Approval can be refused because another parcel was approved meanwhile.
      setDetail({ parcel, conflicts: await api.conflicts(parcel.id) });
    } finally {
      setBusy(false);
    }
  }

  const blocking = conflicts.filter((c) => c.blocking);

  return (
    <div className="workspace">
      <aside className="sidebar">
        <h2>Pending surveys ({queue.length})</h2>
        {queue.length === 0 && <p className="muted">No surveys awaiting review.</p>}
        <ul className="queue">
          {queue.map((p) => (
            <li key={p.id}>
              <button aria-pressed={p.id === selectedId} onClick={() => select(p.id)}>
                <div className="deed">{p.title_deed_no}</div>
                <div className="muted">{p.owner_name} · {p.area_sqm.toFixed(1)} m²</div>
              </button>
            </li>
          ))}
        </ul>

        {message && <div className={`alert ${message.ok ? "ok" : ""}`}>{message.text}</div>}

        {parcel && (
          <>
            <h3>{parcel.title_deed_no} — {parcel.owner_name}</h3>
            <AreaSummary areaSqm={parcel.area_sqm} perimeterM={parcel.perimeter_m} />

            <h3>Boundary conflicts ({conflicts.length})</h3>
            {conflicts.length === 0 ? (
              <p className="muted">No overlap with any registered or pending parcel.</p>
            ) : (
              <table className="data">
                <thead>
                  <tr><th>Parcel</th><th></th><th className="num">Overlap m²</th><th className="num">ft²</th></tr>
                </thead>
                <tbody>
                  {conflicts.map((c) => (
                    <tr key={c.parcel_id}>
                      <td>
                        <div>{c.title_deed_no}</div>
                        <div className="muted">{c.owner_name}</div>
                      </td>
                      <td>
                        <span className={`badge ${c.blocking ? "blocking" : "warning"}`}>
                          {c.blocking ? "APPROVED" : "PENDING"}
                        </span>
                      </td>
                      <td className="num">{c.overlap_area_sqm.toFixed(4)}</td>
                      <td className="num">{(c.overlap_area_sqm * SQFT_PER_SQM).toFixed(2)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
            {blocking.length > 0 && (
              <p className="muted">
                Encroaches on {blocking.length} approved parcel{blocking.length > 1 ? "s" : ""}; it cannot be
                approved until the boundary is resurveyed.
              </p>
            )}

            <h3>Decision</h3>
            <textarea placeholder="Review note (recorded in the audit trail)" value={note}
                      onChange={(e) => setNote(e.target.value)} />
            <div className="actions">
              <button className="btn primary" disabled={busy || blocking.length > 0} onClick={() => review("approve")}>
                Approve
              </button>
              <button className="btn danger" disabled={busy} onClick={() => review("reject")}>Reject</button>
              <Link className="btn" href={`/parcels/${parcel.id}/certificate`}>Survey plan</Link>
            </div>
          </>
        )}
      </aside>
      <div className="map-wrap">
        <CadastraMap tileVersion={tileVersion} highlight={parcel?.boundary} fitTo={parcel?.boundary}
                     conflicts={conflicts} vertexLabels onParcelClick={(p) => p.status === "PENDING" && select(p.id)} />
        <div className="legend">
          <span><span className="swatch" style={{ background: "#1d4ed8" }} />Survey under review</span>
          <span><span className="swatch" style={{ background: "rgba(220,38,38,.65)" }} />Overlap with approved</span>
          <span><span className="swatch" style={{ background: "rgba(220,38,38,.35)" }} />Overlap with pending</span>
        </div>
      </div>
    </div>
  );
}
