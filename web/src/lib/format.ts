const SQM_PER_ACRE = 4046.8564224;

export const formatSqm = (sqm: number) => `${sqm.toLocaleString("en-GB", { maximumFractionDigits: 1, minimumFractionDigits: 1 })} m²`;
export const formatAcres = (sqm: number) => (sqm / SQM_PER_ACRE).toFixed(3);
export const formatMetres = (m: number) => `${m.toFixed(1)} m`;

export function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

/** "Today, 10:42", "Yesterday", "29 Oct", or a full date in another year. */
export function formatWhen(iso: string, now = new Date()) {
  const d = new Date(iso);
  const days = Math.floor((startOfDay(now) - startOfDay(d)) / 86_400_000);
  if (days === 0) return `Today, ${d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" })}`;
  if (days === 1) return "Yesterday";
  return d.toLocaleDateString("en-GB", { day: "numeric", month: "short", ...(d.getFullYear() !== now.getFullYear() && { year: "numeric" }) });
}

/** "5 min ago", "2 h ago", "Yesterday", "29 Oct". */
export function timeAgo(iso: string, now = new Date()) {
  const minutes = Math.round((now.getTime() - new Date(iso).getTime()) / 60_000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes} min ago`;
  if (minutes < 24 * 60 && new Date(iso).getDate() === now.getDate()) return `${Math.floor(minutes / 60)} h ago`;
  return formatWhen(iso, now);
}

export function initials(name: string) {
  const parts = name.trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts.length > 1 ? parts[parts.length - 1][0] : "")).toUpperCase();
}

function startOfDay(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}
