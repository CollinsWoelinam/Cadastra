"""Certificate issuing and public verification."""

import secrets
from uuid import UUID

from psycopg import Connection, errors
from psycopg.types.json import Jsonb

# No 0/O or 1/I: codes are read off paper and typed in.
CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 8
MISS_WINDOW_MINUTES = 15
MAX_MISSES = 20

CERTIFICATE_COLUMNS = """
    c.id, c.number, c.code, c.parcel_id, c.issued_at, c.snapshot,
    (SELECT full_name FROM users u WHERE u.id = c.issued_by) AS issued_by_name
"""

# What a certificate certifies, read from the live record.
_SNAPSHOT_SQL = """
    SELECT title_deed_no, owner_name, status, round(area_sqm::numeric, 1)::float AS area_sqm,
           round(perimeter_m::numeric, 1)::float AS perimeter_m, ST_NPoints(boundary) - 1 AS corners,
           md5(ST_AsBinary(boundary)) AS boundary_hash
    FROM parcels WHERE id = %s
"""
_COMPARED = ("title_deed_no", "owner_name", "status", "area_sqm", "corners")


def format_code(code: str) -> str:
    return f"CDX-{code[:4]}-{code[4:]}"


def normalise_code(text: str) -> str:
    """Accepts "CDX-7K4M-Q2PA", "7k4mq2pa" and the like."""
    raw = "".join(ch for ch in text.upper() if ch.isalnum())
    return raw[3:] if raw.startswith("CDX") and len(raw) == CODE_LENGTH + 3 else raw


def snapshot(conn: Connection, parcel_id: UUID) -> dict | None:
    return conn.execute(_SNAPSHOT_SQL, (parcel_id,)).fetchone()


def issue(conn: Connection, parcel_id: UUID, issued_by: UUID) -> dict:
    snap = snapshot(conn, parcel_id)
    for _ in range(5):
        code = "".join(secrets.choice(CODE_ALPHABET) for _ in range(CODE_LENGTH))
        try:
            with conn.transaction():
                return conn.execute(f"""
                    WITH c AS (
                        INSERT INTO certificates (number, code, parcel_id, issued_by, snapshot)
                        VALUES ('C-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('certificate_number_seq')::text, 6, '0'),
                                %s, %s, %s, %s)
                        RETURNING *
                    )
                    SELECT {CERTIFICATE_COLUMNS} FROM c
                """, (code, parcel_id, issued_by, Jsonb(snap))).fetchone()
        except errors.UniqueViolation:
            continue  # astronomically unlikely code collision
    raise RuntimeError("could not allocate a certificate code")


def changes(certified: dict, current: dict) -> list[dict]:
    found = [{"field": f, "certified": certified.get(f), "current": current.get(f)}
             for f in _COMPARED if certified.get(f) != current.get(f)]
    if certified.get("boundary_hash") != current.get("boundary_hash"):
        found.append({"field": "boundary", "certified": "as certified", "current": "changed"})
    return found


def for_parcel(conn: Connection, parcel_id: UUID) -> list[dict]:
    rows = conn.execute(f"""
        SELECT {CERTIFICATE_COLUMNS} FROM certificates c WHERE c.parcel_id = %s ORDER BY c.issued_at DESC
    """, (parcel_id,)).fetchall()
    current = snapshot(conn, parcel_id)
    for row in rows:
        row["current"] = not changes(row["snapshot"], current)
    return rows


def by_code(conn: Connection, code: str) -> dict | None:
    return conn.execute(f"SELECT {CERTIFICATE_COLUMNS} FROM certificates c WHERE c.code = %s", (code,)).fetchone()


def misses_exceeded(conn: Connection, ip: str | None) -> bool:
    if not ip:
        return False
    n = conn.execute("""
        SELECT count(*) AS n FROM verification_misses
        WHERE ip = %s AND at > now() - make_interval(mins => %s)
    """, (ip, MISS_WINDOW_MINUTES)).fetchone()["n"]
    return n >= MAX_MISSES


def record_miss(conn: Connection, ip: str | None) -> None:
    conn.execute("INSERT INTO verification_misses (ip) VALUES (%s)", (ip,))
    conn.execute("DELETE FROM verification_misses WHERE at < now() - interval '1 day'")
