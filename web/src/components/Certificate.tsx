"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import CadastraMap from "@/components/CadastraMap";
import QrCode from "@/components/QrCode";
import { api, ApiError, formatBearing, FT_PER_M, type Certificate as Cert, type Parcel, type SurveyPlan } from "@/lib/api";
import { formatDate } from "@/lib/format";
import { canReview, useMe } from "@/components/Session";
import { BrandMark, DownloadIcon, WarningIcon } from "@/components/Icons";

declare global {
  interface Window { __certReady?: boolean }
}

const GNG = 2136;
const GMG = 25000;
// The address printed under the QR code; set for deployments where the PDF renderer
// reaches the portal on an internal address.
const PUBLIC_URL = process.env.NEXT_PUBLIC_PORTAL_URL;

const fmt = (n: number, digits: number) =>
  n.toLocaleString("en-GB", { minimumFractionDigits: digits, maximumFractionDigits: digits });
const longDate = (iso: string) => new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

export default function Certificate({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const me = useMe();
  const [data, setData] = useState<{ parcel: Parcel; plan: SurveyPlan; certs: Cert[] } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [mapReady, setMapReady] = useState(false);
  const [issuing, setIssuing] = useState(false);

  useEffect(() => {
    Promise.all([api.parcel(id), api.surveyPlan(id), api.certificates(id)])
      .then(([parcel, plan, certs]) => setData({ parcel, plan, certs }))
      .catch((e) => setError(String(e.message)));
  }, [id]);

  const ready = !!data && mapReady;
  useEffect(() => {
    // Polled by the PDF renderer before it prints.
    window.__certReady = ready;
  }, [ready]);

  async function issue() {
    setIssuing(true);
    setError(null);
    try {
      const cert = await api.issueCertificate(id);
      setData((d) => d && { ...d, certs: [{ ...cert, current: true }, ...d.certs] });
    } catch (e) {
      setError(e instanceof ApiError ? e.message : String(e));
    } finally {
      setIssuing(false);
    }
  }

  if (!data) {
    return <div className="cert-page"><div className="certificate">{error ? <div className="alert">{error}</div> : <p className="muted">Loading…</p>}</div></div>;
  }

  const { parcel, plan, certs } = data;
  const latest = certs[0];
  const cert = latest?.current ? latest : null;
  const approved = parcel.status === "APPROVED";
  // Only reached in the browser: data loads client-side, so server and client markup agree.
  const origin = PUBLIC_URL ?? window.location.origin;
  const verifyUrl = cert ? `${origin}/verify/${cert.code}` : "";

  return (
    <div className="cert-page">
      <div className="cert-toolbar">
        <Link href="/" className="btn btn-sm">Back to the map</Link>
        <span style={{ flex: 1 }} />
        {latest && !latest.current && (
          <span className="cert-toolbar-note"><WarningIcon size={16} color="#9A5B05" />The record changed after {latest.number} was issued.</span>
        )}
        {approved && !cert && canReview(me) && (
          <button type="button" className="btn btn-sm btn-primary" disabled={issuing} onClick={issue}>
            {issuing ? "Issuing…" : latest ? "Issue a new certificate" : "Issue certificate"}
          </button>
        )}
        <a className="btn btn-sm" href={`/api/certificates/${id}`}><DownloadIcon size={16} />Download PDF</a>
      </div>
      {error && <div className="cert-toolbar"><div className="alert" style={{ flex: 1 }}>{error}</div></div>}

      <article className="certificate" data-ready={ready}>
        {!approved && <div className="watermark">{parcel.status === "REJECTED" ? "REJECTED" : "PROVISIONAL"}</div>}
        <header className="cert-head">
          <div className="cert-title">
            <div className="cert-issuer"><BrandMark size={26} ring="#0B6E4F" /><span>LANDS REGISTRY · GHANA</span></div>
            <h1>{cert ? "Cadastral Survey Certificate" : approved ? "Survey Plan" : "Provisional Survey Plan"}</h1>
            <div className="cert-meta">
              {cert ? (
                <><span>Certificate <strong className="mono">{cert.number}</strong></span><span>Issued <strong>{longDate(cert.issued_at)}</strong></span></>
              ) : (
                <span>Printed <strong>{longDate(new Date().toISOString())}</strong> · not a certificate</span>
              )}
            </div>
          </div>
          {cert && (
            <div className="cert-qr">
              <div className="cert-qr-text">
                <span>Scan to verify</span>
                <strong className="mono">{cert.code}</strong>
                <span>{origin.replace(/^https?:\/\//, "")}/verify</span>
              </div>
              <QrCode value={verifyUrl} size={96} label={`QR code linking to ${verifyUrl}`} />
            </div>
          )}
        </header>

        <dl className="cert-facts">
          <div><dt>Title deed</dt><dd className="mono">{parcel.title_deed_no}</dd></div>
          <div><dt>Registered owner</dt><dd>{parcel.owner_name}</dd></div>
          <div><dt>Status</dt><dd className={approved ? "ok" : ""}>
            {approved ? "Approved" : parcel.status === "PENDING" ? "Pending review" : "Rejected"}
            {parcel.reviewed_at && ` ${formatDate(parcel.reviewed_at)}`}</dd></div>
          <div><dt>Surveyed by</dt><dd>{parcel.submitted_by_name ?? "—"}</dd></div>
          <div><dt>Area</dt><dd>{fmt(plan.area.sqm, 1)} m²</dd></div>
          <div><dt>Hectares · acres</dt><dd>{fmt(plan.area.hectares, 4)} ha · {fmt(plan.area.acres, 3)} ac</dd></div>
          <div><dt>Perimeter</dt><dd>{fmt(plan.perimeter_m, 1)} m · {fmt(plan.perimeter_m * FT_PER_M, 1)} ft</dd></div>
          <div><dt>Survey accuracy</dt><dd>{parcel.survey_accuracy_m != null ? `±${parcel.survey_accuracy_m.toFixed(2)} m` : "Not recorded"}</dd></div>
        </dl>

        <CadastraMap className="cert-map" highlight={parcel.boundary} fitTo={parcel.boundary} vertexLabels
                     interactive={false} printable onReady={() => setMapReady(true)} />

        <section>
          <h2 className="cert-h2">Boundary vertex schedule</h2>
          <table className="cert-table">
            <thead>
              <tr>
                <th>No.</th>
                <th>Easting (ft)</th><th>Northing (ft)</th><th>Easting (m)</th><th>Northing (m)</th><th>Latitude</th><th>Longitude</th>
              </tr>
            </thead>
            <tbody>
              {plan.vertices.map((v) => (
                <tr key={v.no}>
                  <td>{v.no}</td>
                  <td>{fmt(v[`epsg_${GNG}`].x, 2)}</td><td>{fmt(v[`epsg_${GNG}`].y, 2)}</td>
                  <td>{fmt(v[`epsg_${GMG}`].x, 2)}</td><td>{fmt(v[`epsg_${GMG}`].y, 2)}</td>
                  <td>{v.lat.toFixed(7)}</td><td>{v.lon.toFixed(7)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="cert-note">
            Feet: {plan.crs.find((c) => c.epsg === GNG)?.name} (EPSG:{GNG}, Gold Coast feet). Metres: Leigon / Ghana Metre
            Grid (EPSG:{GMG}). Lat/long: WGS 84.
          </p>
        </section>

        <section>
          <h2 className="cert-h2">Boundary legs</h2>
          <table className="cert-table">
            <thead><tr><th>From → to</th><th>True bearing</th><th>Distance (m)</th><th>Distance (ft)</th></tr></thead>
            <tbody>
              {plan.legs.map((l) => (
                <tr key={l.from}>
                  <td>{l.from} → {l.to}</td><td>{formatBearing(l.bearing_deg)}</td>
                  <td>{fmt(l.length_m, 3)}</td><td>{fmt(l.length_m * FT_PER_M, 2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>

        <div className="cert-signatures">
          <div><strong>{parcel.submitted_by_name ?? "—"}</strong>Surveyor · {formatDate(parcel.created_at)}</div>
          <div><strong>{parcel.reviewed_by_name ?? (parcel.reviewed_at ? "—" : "Awaiting review")}</strong>
            {parcel.reviewed_at ? `Reviewer, Lands Registry · ${formatDate(parcel.reviewed_at)}` : "Reviewer, Lands Registry"}</div>
          <div><strong>Registry seal</strong>{cert ? `Certificate ${cert.number}` : "Not certified"}</div>
        </div>

        <footer className="cert-footer">
          Area and distances are geodetic (WGS 84 ellipsoid). {gridAccuracyNote(plan.crs)}
          {cert && ` Verify this certificate with code ${cert.code}; the registry record prevails over this document.`}
          {!approved && " This parcel has not been approved and this document confers no rights."}
        </footer>
      </article>
    </div>
  );
}

/** States how the grid coordinates were derived and how far to trust them. */
function gridAccuracyNote(crs: SurveyPlan["crs"]): string {
  // Grids on another datum than WGS 84; UTM needs no datum change.
  const grids = crs.filter((c) => c.transformation.accuracy_m !== null);
  const datum = (c: SurveyPlan["crs"][number]) => c.name.split(" / ")[0];
  const list = (cs: SurveyPlan["crs"]) => cs.map((c) => `${datum(c)} ±${c.transformation.accuracy_m} m`).join(", ");
  const local = grids.filter((c) => c.transformation.source !== "EPSG");
  const epsg = grids.filter((c) => c.transformation.source === "EPSG");
  const datums = (cs: SurveyPlan["crs"]) =>
    `the ${cs.map(datum).join(" and ")} datum${cs.length > 1 ? "s" : ""}`;
  const sources = [...new Set(local.map((c) => c.transformation.source))];
  const notes = sources.map((source) => {
    const cs = local.filter((c) => c.transformation.source === source);
    return `Grid coordinates on ${datums(cs)} use parameters from ${source} (${list(cs)}).`;
  });
  if (epsg.length) {
    notes.push(
      `Grid coordinates${local.length ? ` on ${datums(epsg)}` : ""} use the standard EPSG datum ` +
        `transformation${epsg.length > 1 ? "s" : ""} (${list(epsg)}) and are indicative until local ` +
        "transformation parameters from the Survey and Mapping Division are applied.",
    );
  }
  return notes.join(" ");
}
