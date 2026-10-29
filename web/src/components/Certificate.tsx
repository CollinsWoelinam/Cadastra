"use client";

import { use, useEffect, useState } from "react";
import CadastraMap from "@/components/CadastraMap";
import { api, formatBearing, FT_PER_M, type Parcel, type SurveyPlan } from "@/lib/api";

declare global {
  interface Window { __certReady?: boolean }
}

const GNG = 2136;
const GMG = 25000;

const fmt = (n: number, digits: number) =>
  n.toLocaleString("en-GB", { minimumFractionDigits: digits, maximumFractionDigits: digits });

export default function Certificate({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [parcel, setParcel] = useState<Parcel | null>(null);
  const [plan, setPlan] = useState<SurveyPlan | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Promise.all([api.parcel(id), api.surveyPlan(id)])
      .then(([p, s]) => { setParcel(p); setPlan(s); })
      .catch((e) => setError(String(e.message)));
  }, [id]);

  useEffect(() => {
    // Polled by the PDF renderer before it prints.
    window.__certReady = ready;
  }, [ready]);

  if (error) return <div className="certificate"><div className="alert">{error}</div></div>;
  if (!parcel || !plan) return <div className="certificate"><p className="muted">Loading…</p></div>;

  const gngName = plan.crs.find((c) => c.epsg === GNG)?.name;
  const issued = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

  return (
    <>
      <div className="cert-toolbar">
        <a className="btn" href={`/api/certificates/${id}`}>Download PDF</a>
      </div>
      <article className="certificate" data-ready={ready}>
        {parcel.status !== "APPROVED" && <div className="watermark">{parcel.status === "REJECTED" ? "REJECTED" : "PROVISIONAL"}</div>}
        <header>
          <h1>CADASTRAL SURVEY CERTIFICATE</h1>
          <div className="muted">Cadastra Land Registry · Ghana</div>
        </header>

        <div className="grid2">
          <dl className="props">
            <dt>Title deed no.</dt><dd><strong>{parcel.title_deed_no}</strong></dd>
            <dt>Registered owner</dt><dd>{parcel.owner_name}</dd>
            <dt>Status</dt><dd>{parcel.status}{parcel.reviewed_at && ` · ${new Date(parcel.reviewed_at).toLocaleDateString("en-GB")}`}</dd>
            <dt>Parcel ID</dt><dd style={{ fontSize: 11 }}>{parcel.id}</dd>
          </dl>
          <dl className="props">
            <dt>Area</dt><dd>{fmt(plan.area.sqm, 2)} m²</dd>
            <dt></dt><dd>{fmt(plan.area.hectares, 4)} ha · {fmt(plan.area.acres, 4)} acres</dd>
            <dt>Perimeter</dt><dd>{fmt(plan.perimeter_m, 2)} m · {fmt(plan.perimeter_m * FT_PER_M, 2)} ft</dd>
            <dt>Vertices</dt><dd>{plan.vertices.length}</dd>
          </dl>
        </div>

        <CadastraMap className="cert-map" highlight={parcel.boundary} fitTo={parcel.boundary} vertexLabels
                     interactive={false} printable onReady={() => setReady(true)} />

        <h3>Boundary vertex schedule</h3>
        <table className="data">
          <thead>
            <tr>
              <th>No.</th>
              <th className="num">Easting (ft)</th><th className="num">Northing (ft)</th>
              <th className="num">Easting (m)</th><th className="num">Northing (m)</th>
              <th className="num">Latitude</th><th className="num">Longitude</th>
            </tr>
          </thead>
          <tbody>
            {plan.vertices.map((v) => (
              <tr key={v.no}>
                <td>{v.no}</td>
                <td className="num">{fmt(v[`epsg_${GNG}`].x, 2)}</td>
                <td className="num">{fmt(v[`epsg_${GNG}`].y, 2)}</td>
                <td className="num">{fmt(v[`epsg_${GMG}`].x, 2)}</td>
                <td className="num">{fmt(v[`epsg_${GMG}`].y, 2)}</td>
                <td className="num">{v.lat.toFixed(7)}</td>
                <td className="num">{v.lon.toFixed(7)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="muted">
          Feet: {gngName} (EPSG:{GNG}, Gold Coast feet). Metres: Leigon / Ghana Metre Grid (EPSG:{GMG}).
          Lat/long: WGS 84.
        </p>

        <h3>Boundary legs</h3>
        <table className="data">
          <thead>
            <tr><th>From</th><th>To</th><th className="num">True bearing</th><th className="num">Distance (m)</th><th className="num">Distance (ft)</th></tr>
          </thead>
          <tbody>
            {plan.legs.map((l) => (
              <tr key={l.from}>
                <td>{l.from}</td><td>{l.to}</td>
                <td className="num">{formatBearing(l.bearing_deg)}</td>
                <td className="num">{fmt(l.length_m, 3)}</td>
                <td className="num">{fmt(l.length_m * FT_PER_M, 2)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <footer>
          Issued {issued}. Area and distances are geodetic (WGS 84 ellipsoid). Grid coordinates are derived using
          the standard EPSG datum transformations, which are accurate to approximately ±5–6 m; they are indicative
          until local transformation parameters from the Survey and Mapping Division are applied.
          {parcel.status !== "APPROVED" && " This parcel has not been approved and this document confers no rights."}
        </footer>
      </article>
    </>
  );
}
