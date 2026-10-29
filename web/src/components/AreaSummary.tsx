import { FT_PER_M } from "@/lib/api";

const SQM_PER_ACRE = 4046.8564224;

export function AreaSummary({ areaSqm, perimeterM }: { areaSqm: number; perimeterM: number }) {
  return (
    <dl className="props">
      <dt>Area</dt>
      <dd>{areaSqm.toLocaleString(undefined, { maximumFractionDigits: 2 })} m²</dd>
      <dt></dt>
      <dd>{(areaSqm / 10_000).toFixed(4)} ha · {(areaSqm / SQM_PER_ACRE).toFixed(4)} acres</dd>
      <dt>Perimeter</dt>
      <dd>{perimeterM.toFixed(2)} m · {(perimeterM * FT_PER_M).toFixed(2)} ft</dd>
    </dl>
  );
}
