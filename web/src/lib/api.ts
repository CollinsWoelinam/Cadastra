import type { Polygon, MultiPolygon } from "geojson";

export type ParcelStatus = "PENDING" | "APPROVED" | "REJECTED";

export interface Parcel {
  id: string;
  title_deed_no: string;
  owner_name: string;
  boundary: Polygon;
  area_sqm: number;
  perimeter_m: number;
  survey_accuracy_m: number | null;
  status: ParcelStatus;
  review_note: string | null;
  reviewed_at: string | null;
  created_at: string;
  submitted_by: string | null;
  submitted_by_name: string | null;
  reviewed_by: string | null;
  reviewed_by_name: string | null;
}

export interface Conflict {
  parcel_id: string;
  title_deed_no: string;
  owner_name: string;
  status: ParcelStatus;
  overlap_area_sqm: number;
  overlap_geometry: Polygon | MultiPolygon;
  blocking: boolean;
}

export interface ParcelEvent {
  event_type: string;
  detail: Record<string, unknown>;
  at: string;
  actor_name: string | null;
}

interface XY {
  x: number;
  y: number;
}

export interface SurveyPlan {
  parcel_id: string;
  title_deed_no: string;
  owner_name: string;
  crs: { epsg: number; name: string; unit: string }[];
  vertices: ({ no: number; lon: number; lat: number } & Record<`epsg_${number}`, XY>)[];
  legs: { from: number; to: number; bearing_deg: number; length_m: number }[];
  area: { sqm: number; hectares: number; acres: number };
  perimeter_m: number;
}

export type Role = "SURVEYOR" | "REVIEWER" | "ADMIN";

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  is_active: boolean;
  created_at: string;
  last_active_at: string | null;
}

/** Human-readable text for an API error body's `detail`. */
export function detailMessage(detail: unknown, fallback: string): string {
  if (typeof detail === "string") return detail;
  // Request validation errors: [{ loc, msg }, ...]
  if (Array.isArray(detail)) return detail.map((d: { msg?: string }) => d.msg).filter(Boolean).join("; ") || fallback;
  return (detail as { message?: string })?.message ?? fallback;
}

export class ApiError extends Error {
  constructor(public status: number, public detail: unknown) {
    super(detailMessage(detail, `HTTP ${status}`));
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`/core${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
    cache: "no-store",
  });
  const body = await res.json().catch(() => null);
  if (res.status === 401 && typeof window !== "undefined") {
    // Session ended (expired, revoked, or account disabled).
    // Full reload, not router.push: hidden routes stay mounted (Activity) and would keep the
    // previous session's data in memory.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign(`/login?next=${encodeURIComponent(location.pathname + location.search)}`);
  }
  if (!res.ok) throw new ApiError(res.status, body?.detail ?? body);
  return body as T;
}

export const api = {
  parcel: (id: string) => request<Parcel>(`/parcels/${id}`),
  parcels: (status?: ParcelStatus) =>
    request<{ features: { properties: Omit<Parcel, "boundary">; geometry: Polygon }[] }>(
      `/parcels${status ? `?status=${status}` : ""}`,
    ).then((fc) => fc.features.map((f): Parcel => ({ ...f.properties, boundary: f.geometry }))),
  extent: () => request<[number, number, number, number] | null>("/parcels/extent"),
  conflicts: (id: string) => request<Conflict[]>(`/parcels/${id}/conflicts`),
  events: (id: string) => request<ParcelEvent[]>(`/parcels/${id}/events`),
  surveyPlan: (id: string) => request<SurveyPlan>(`/parcels/${id}/survey-plan`),
  approve: (id: string, note: string) =>
    request<Parcel>(`/parcels/${id}/approve`, { method: "POST", body: JSON.stringify({ note: note || null }) }),
  reject: (id: string, note: string) =>
    request<Parcel>(`/parcels/${id}/reject`, { method: "POST", body: JSON.stringify({ note: note || null }) }),
  users: () => request<User[]>("/users"),
  createUser: (body: { email: string; full_name: string; password: string; role: Role }) =>
    request<User>("/users", { method: "POST", body: JSON.stringify(body) }),
  updateUser: (id: string, patch: Partial<Pick<User, "full_name" | "role" | "is_active">> & { password?: string }) =>
    request<User>(`/users/${id}`, { method: "PATCH", body: JSON.stringify(patch) }),
};

export const SQFT_PER_SQM = 10.763910416709722;
export const FT_PER_M = 3.280839895013123;

export function formatBearing(deg: number): string {
  let d = Math.floor(deg);
  let m = Math.floor((deg - d) * 60);
  let s = Math.round(((deg - d) * 60 - m) * 60);
  if (s === 60) { s = 0; m += 1; }
  if (m === 60) { m = 0; d += 1; }
  return `${String(d % 360).padStart(3, "0")}° ${String(m).padStart(2, "0")}′ ${String(s).padStart(2, "0")}″`;
}
