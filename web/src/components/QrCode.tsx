import QRCode from "qrcode";

/** A QR code drawn as SVG squares (crisp in print, no canvas or images). */
export default function QrCode({ value, size, label }: { value: string; size: number; label: string }) {
  const { modules } = QRCode.create(value, { errorCorrectionLevel: "M" });
  const n = modules.size;
  const quiet = 2;
  const cells: string[] = [];
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      if (modules.get(y, x)) cells.push(`M${x + quiet} ${y + quiet}h1v1h-1z`);
    }
  }
  return (
    <svg role="img" aria-label={label} width={size} height={size} viewBox={`0 0 ${n + 2 * quiet} ${n + 2 * quiet}`}
         shapeRendering="crispEdges" style={{ display: "block", background: "#fff" }}>
      <path d={cells.join("")} fill="#0F1B17" />
    </svg>
  );
}
