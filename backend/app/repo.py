import json
from uuid import UUID

from psycopg import Connection
from psycopg.types.json import Jsonb

from .config import settings

PARCEL_COLUMNS = """
    id, client_ref, title_deed_no, owner_name, ST_AsGeoJSON(boundary)::json AS boundary,
    area_sqm, perimeter_m, survey_accuracy_m, status, review_note, reviewed_at, created_at
"""

# 'T********' = interiors intersect. Unlike ST_Overlaps this also catches one parcel
# lying wholly inside another and identical boundaries, while ignoring parcels that
# merely share an edge or a corner.
CONFLICTS_SQL = """
    WITH proposed AS ({proposed}),
    hits AS (
        SELECT p.id, p.title_deed_no, p.owner_name, p.status,
               ST_CollectionExtract(ST_Intersection(p.boundary, proposed.g), 3) AS overlap
        FROM parcels p, proposed
        WHERE p.status = ANY(%(statuses)s)
          AND p.boundary && proposed.g
          AND ST_Relate(p.boundary, proposed.g, 'T********')
          AND p.id IS DISTINCT FROM %(parcel_id)s
    )
    SELECT id AS parcel_id, title_deed_no, owner_name, status,
           ST_Area(overlap::geography) AS overlap_area_sqm,
           ST_AsGeoJSON(overlap)::json AS overlap_geometry,
           status = 'APPROVED' AS blocking
    FROM hits
    WHERE ST_Area(overlap::geography) > %(tolerance)s
    ORDER BY blocking DESC, overlap_area_sqm DESC
"""


def find_conflicts(conn: Connection, *, geojson: dict | None = None, parcel_id: UUID | None = None,
                   statuses: tuple[str, ...] = ("APPROVED", "PENDING")) -> list[dict]:
    """Conflicts for a proposed boundary, or for a stored parcel against all others.

    Stored parcels are compared using their stored geometry: round-tripping through
    GeoJSON rounds coordinates and can turn a shared edge into a sub-millimetre overlap.
    """
    if parcel_id is not None:
        proposed = "SELECT boundary AS g FROM parcels WHERE id = %(parcel_id)s"
    else:
        proposed = "SELECT ST_SetSRID(ST_GeomFromGeoJSON(%(geojson)s), 4326) AS g"
    return conn.execute(CONFLICTS_SQL.format(proposed=proposed), {
        "geojson": json.dumps(geojson),
        "parcel_id": parcel_id,
        "statuses": list(statuses),
        "tolerance": settings.overlap_tolerance_sqm,
    }).fetchall()


def check_geometry(conn: Connection, geojson: dict) -> dict:
    return conn.execute("""
        WITH g AS (SELECT ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326) AS g)
        SELECT ST_IsValid(g) AS valid,
               CASE WHEN ST_IsValid(g) THEN NULL ELSE ST_IsValidReason(g) END AS reason,
               ST_Area(g::geography) AS area_sqm,
               ST_Perimeter(g::geography) AS perimeter_m
        FROM g
    """, (json.dumps(geojson),)).fetchone()


def get_parcel(conn: Connection, parcel_id: UUID, for_update: bool = False) -> dict | None:
    lock = " FOR UPDATE" if for_update else ""
    return conn.execute(f"SELECT {PARCEL_COLUMNS} FROM parcels WHERE id = %s{lock}",
                        (parcel_id,)).fetchone()


def get_parcel_by_client_ref(conn: Connection, client_ref: UUID) -> dict | None:
    return conn.execute(f"SELECT {PARCEL_COLUMNS} FROM parcels WHERE client_ref = %s",
                        (client_ref,)).fetchone()


def insert_parcel(conn: Connection, sub, survey_accuracy_m: float | None) -> dict:
    row = conn.execute(f"""
        INSERT INTO parcels (client_ref, title_deed_no, owner_name, boundary, survey_accuracy_m)
        VALUES (%s, %s, %s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326), %s)
        RETURNING {PARCEL_COLUMNS}
    """, (sub.client_ref, sub.title_deed_no, sub.owner_name,
          sub.boundary.model_dump_json(), survey_accuracy_m)).fetchone()
    with conn.cursor() as cur:
        cur.executemany("""
            INSERT INTO survey_points (parcel_id, seq, geom, accuracy_m, captured_at)
            VALUES (%s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s, %s)
        """, [(row["id"], i, p.lon, p.lat, p.accuracy_m, p.captured_at)
              for i, p in enumerate(sub.survey_points, start=1)])
    return row


def set_status(conn: Connection, parcel_id: UUID, status: str, note: str | None) -> dict:
    return conn.execute(f"""
        UPDATE parcels SET status = %s, review_note = %s, reviewed_at = now()
        WHERE id = %s RETURNING {PARCEL_COLUMNS}
    """, (status, note, parcel_id)).fetchone()


def record_event(conn: Connection, parcel_id: UUID, event_type: str, detail: dict) -> None:
    conn.execute("INSERT INTO parcel_events (parcel_id, event_type, detail) VALUES (%s, %s, %s)",
                 (parcel_id, event_type, Jsonb(detail)))


def list_events(conn: Connection, parcel_id: UUID) -> list[dict]:
    return conn.execute("""
        SELECT event_type, detail, at FROM parcel_events WHERE parcel_id = %s ORDER BY at, id
    """, (parcel_id,)).fetchall()


def list_parcels(conn: Connection, bbox: tuple[float, float, float, float] | None,
                 status: str | None, limit: int) -> list[dict]:
    clauses, params = [], []
    if bbox:
        clauses.append("boundary && ST_MakeEnvelope(%s, %s, %s, %s, 4326)")
        params.extend(bbox)
    if status:
        clauses.append("status = %s")
        params.append(status)
    where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    return conn.execute(f"SELECT {PARCEL_COLUMNS} FROM parcels {where} ORDER BY created_at LIMIT %s",
                        (*params, limit)).fetchall()


def tile(conn: Connection, z: int, x: int, y: int) -> bytes:
    row = conn.execute("""
        WITH bounds AS (SELECT ST_TileEnvelope(%(z)s, %(x)s, %(y)s) AS env),
        mvt AS (
            SELECT p.id::text, p.title_deed_no, p.owner_name, p.status, p.area_sqm,
                   ST_AsMVTGeom(ST_Transform(p.boundary, 3857), bounds.env) AS geom
            FROM parcels p, bounds
            WHERE p.boundary && ST_Transform(bounds.env, 4326)
        )
        SELECT ST_AsMVT(mvt, 'parcels', 4096, 'geom') AS tile FROM mvt
    """, {"z": z, "x": x, "y": y}).fetchone()
    return bytes(row["tile"])


def extent(conn: Connection) -> list[float] | None:
    row = conn.execute("""
        SELECT ST_XMin(e) AS minx, ST_YMin(e) AS miny, ST_XMax(e) AS maxx, ST_YMax(e) AS maxy
        FROM (SELECT ST_Extent(boundary) AS e FROM parcels) s
    """).fetchone()
    return None if row["minx"] is None else [row["minx"], row["miny"], row["maxx"], row["maxy"]]
