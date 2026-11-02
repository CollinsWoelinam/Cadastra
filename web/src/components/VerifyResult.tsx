import { headers } from "next/headers";
import { connection } from "next/server";
import type { Verification } from "@/lib/api";
import { CORE_API_URL } from "@/lib/session";
import { formatDate, formatSqm } from "@/lib/format";
import VerifyForm from "@/components/VerifyForm";
import VerifyMap from "@/components/VerifyMap";

const STATUS = { APPROVED: "Approved", PENDING: "Pending review", REJECTED: "Rejected" } as const;
const FIELD = { title_deed_no: "Title deed", owner_name: "Owner", status: "Status", area_sqm: "Area", corners: "Corners", boundary: "Boundary" } as const;

function show(field: string, value: unknown) {
  if (field === "area_sqm" && typeof value === "number") return formatSqm(value);
  if (field === "status") return STATUS[value as keyof typeof STATUS] ?? String(value);
  return String(value);
}

type Lookup = { ok: true; v: Verification } | { ok: false; status: number };

async function lookup(code: string): Promise<Lookup> {
  const forwardedFor = (await headers()).get("x-forwarded-for");
  const res = await fetch(`${CORE_API_URL}/verify/${encodeURIComponent(code)}`, {
    cache: "no-store",
    headers: forwardedFor ? { "X-Forwarded-For": forwardedFor } : {},
  }).catch(() => null);
  if (!res) return { ok: false, status: 502 };
  return res.ok ? { ok: true, v: await res.json() } : { ok: false, status: res.status };
}

export default async function VerifyResult({ params }: { params: Promise<{ code: string }> }) {
  await connection(); // always a live check, never a prerendered one
  const code = decodeURIComponent((await params).code);
  const result = await lookup(code);

  if (!result.ok) {
    const [title, text] = result.status === 404
      ? ["No certificate has this code", "Check the code against the certificate. A certificate whose code is not found here was not issued by the Lands Registry."]
      : result.status === 429
        ? ["Too many unknown codes", "This connection looked up too many codes that do not exist. Try again in 15 minutes."]
        : ["The registry cannot be reached", "Try again shortly."];
    return (
      <>
        <section className="verdict verdict-bad" aria-labelledby="verdict">
          <div className="verdict-head">
            <span className="verdict-icon" aria-hidden="true">!</span>
            <div><h1 id="verdict">{title}</h1><p>{text}</p></div>
            <div className="verdict-code"><span>Code checked</span><strong className="mono">{code}</strong></div>
          </div>
        </section>
        <section className="card verify-again"><h2>Try another code</h2><VerifyForm initial={code} /></section>
        <VerifyExplainer />
      </>
    );
  }

  const { v } = result;
  const genuine = v.verdict === "genuine";
  const checked = new Date(v.checked_at).toLocaleString("en-GB", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit", timeZone: "UTC" });
  return (
    <>
      <section className={`verdict ${genuine ? "verdict-ok" : "verdict-warn"}`} aria-labelledby="verdict">
        <div className="verdict-head">
          <span className="verdict-icon" aria-hidden="true">{genuine ? "✓" : "!"}</span>
          <div>
            <h1 id="verdict">{genuine ? "Genuine certificate" : "Genuine, but out of date"}</h1>
            <p>{genuine
              ? "Issued by the Lands Registry and matching the current record."
              : "The parcel record changed after this certificate was issued. Ask the registry for a current one before relying on it."}</p>
          </div>
          <div className="verdict-code"><span>Verification code</span><strong className="mono">{v.certificate.code}</strong></div>
        </div>
        <div className="verdict-meta">
          <span>Checked {checked} GMT</span>
          <span>Certificate {v.certificate.number}, issued {formatDate(v.certificate.issued_at)}</span>
          <span>{genuine ? "Record unchanged since issue" : `${v.changes.length} change${v.changes.length === 1 ? "" : "s"} since issue`}</span>
        </div>
      </section>

      {!genuine && (
        <section className="card verify-card" aria-labelledby="cmp">
          <h2 id="cmp">What changed</h2>
          <table className="table compare">
            <thead><tr><th scope="col"><span className="visually-hidden">Field</span></th><th scope="col">On certificate</th><th scope="col">Registry now</th></tr></thead>
            <tbody>
              {v.changes.map((c) => (
                <tr key={c.field}>
                  <th scope="row">{FIELD[c.field as keyof typeof FIELD] ?? c.field}</th>
                  <td className="was">{show(c.field, c.certified)}</td>
                  <td className="now">{show(c.field, c.current)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}

      <div className="verify-grid">
        <section className="card verify-card" aria-labelledby="rec">
          <div>
            <h2 id="rec">Registry record</h2>
            <p className="muted" style={{ margin: "6px 0 0" }}>Every value on the paper certificate should match these.</p>
          </div>
          <dl className="record">
            <div><dt>Title deed number</dt><dd className="mono">{v.current.title_deed_no}</dd></div>
            <div><dt>Registered owner</dt><dd className="strong">{v.current.owner_name}</dd></div>
            <div><dt>Status</dt><dd className={v.current.status === "APPROVED" ? "ok" : ""}>
              <span className={`dot ${v.current.status === "APPROVED" ? "dot-green" : "dot-amber"}`} />
              {STATUS[v.current.status]}{v.current.reviewed_at && ` ${formatDate(v.current.reviewed_at)}`}</dd></div>
            <div><dt>Area</dt><dd className="strong">{formatSqm(v.current.area_sqm)} <span className="muted">· {(v.current.area_sqm / 4046.8564224).toFixed(3)} acres</span></dd></div>
            <div><dt>Boundary corners</dt><dd>{v.current.corners}{v.current.survey_accuracy_m != null && ` · surveyed to ±${v.current.survey_accuracy_m.toFixed(2)} m`}</dd></div>
            <div><dt>Perimeter</dt><dd>{v.current.perimeter_m.toFixed(1)} m</dd></div>
          </dl>
        </section>
        <section className="card verify-map-card" aria-labelledby="plan">
          <div style={{ padding: "20px 24px 14px" }}>
            <h2 id="plan">Boundary on record</h2>
            <p className="muted" style={{ margin: "6px 0 0" }}>Compare with the plan printed on the certificate.</p>
          </div>
          <div className="verify-map"><VerifyMap boundary={v.current.boundary} /></div>
        </section>
      </div>

      <section className="card verify-again">
        <div style={{ flex: "1 1 280px" }}>
          <h2>Check another certificate</h2>
          <p className="muted" style={{ margin: "6px 0 0" }}>Scan its QR code, or type the code printed beside it.</p>
        </div>
        <VerifyForm />
      </section>
      <VerifyExplainer />
    </>
  );
}

export function VerifyExplainer() {
  return (
    <section className="verify-explainer" aria-labelledby="covers">
      <h2 id="covers">What this check tells you</h2>
      <p>The certificate was issued by the Lands Registry; its code cannot be guessed or reused.</p>
      <p>The record is shown as it stands today, so a later change is visible.</p>
      <p>It does not replace an official search at the Lands Commission before a sale.</p>
    </section>
  );
}
