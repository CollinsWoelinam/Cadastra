from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request

from .. import certificates as certs, repo
from ..auth import Conn, current_user, require_role

router = APIRouter(dependencies=[Depends(current_user)])
public = APIRouter()
Reviewer = require_role("REVIEWER", "ADMIN")


def _out(row: dict) -> dict:
    return {
        "id": row["id"], "number": row["number"], "code": certs.format_code(row["code"]),
        "parcel_id": row["parcel_id"], "issued_at": row["issued_at"], "issued_by_name": row["issued_by_name"],
        **({"current": row["current"]} if "current" in row else {}),
    }


@router.post("/parcels/{parcel_id}/certificates", status_code=201)
def issue_certificate(parcel_id: UUID, conn: Conn, user=Reviewer):
    parcel = repo.get_parcel(conn, parcel_id, for_update=True)
    if parcel is None:
        raise HTTPException(404, "parcel not found")
    if parcel["status"] != "APPROVED":
        raise HTTPException(409, f"only approved parcels get certificates; this one is {parcel['status']}")
    row = certs.issue(conn, parcel_id, user["id"])
    repo.record_event(conn, parcel_id, "CERTIFICATE_ISSUED", {"number": row["number"]}, user["id"])
    return _out(row)


@router.get("/parcels/{parcel_id}/certificates")
def list_certificates(parcel_id: UUID, conn: Conn):
    """Newest first; `current` is false once the record has changed since issue."""
    if repo.get_parcel(conn, parcel_id) is None:
        raise HTTPException(404, "parcel not found")
    return [_out(r) for r in certs.for_parcel(conn, parcel_id)]


@public.get("/verify/{code}")
def verify(code: str, conn: Conn, request: Request):
    """Public check of a certificate by its code: no sign-in needed."""
    ip = request.client.host if request.client else None
    if certs.misses_exceeded(conn, ip):
        raise HTTPException(429, "too many unknown codes; try again later",
                            headers={"Retry-After": str(certs.MISS_WINDOW_MINUTES * 60)})
    row = certs.by_code(conn, certs.normalise_code(code))
    if row is None:
        certs.record_miss(conn, ip)
        conn.commit()  # keep the miss despite the error response
        raise HTTPException(404, "no certificate has this code")

    parcel = repo.get_parcel(conn, row["parcel_id"])
    current = certs.snapshot(conn, row["parcel_id"])
    found = certs.changes(row["snapshot"], current)
    certified = {k: row["snapshot"][k] for k in ("title_deed_no", "owner_name", "status", "area_sqm", "corners")}
    return {
        "verdict": "outdated" if found else "genuine",
        "checked_at": datetime.now(timezone.utc),
        "certificate": _out(row),
        "certified": certified,
        "current": {
            **{k: current[k] for k in ("title_deed_no", "owner_name", "status", "area_sqm", "perimeter_m", "corners")},
            "boundary": parcel["boundary"],
            "survey_accuracy_m": parcel["survey_accuracy_m"],
            "reviewed_at": parcel["reviewed_at"],
        },
        "changes": found,
    }
