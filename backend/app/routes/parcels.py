from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from psycopg import Connection, errors

from .. import geo, repo
from ..auth import Conn, current_user, require_role
from ..schemas import (Parcel, ParcelSubmission, PolygonGeometry, ReviewDecision,
                       SubmissionResult, ValidationResult)

# Any signed-in user may read; changes are gated per route by role.
router = APIRouter(dependencies=[Depends(current_user)])
Surveyor = require_role("SURVEYOR", "ADMIN")
Reviewer = require_role("REVIEWER", "ADMIN")

# All approvals take this lock so two overlapping PENDING parcels can't both be
# approved by concurrent requests.
APPROVAL_LOCK = 727002


def _require_parcel(conn: Connection, parcel_id: UUID, for_update: bool = False) -> dict:
    parcel = repo.get_parcel(conn, parcel_id, for_update)
    if parcel is None:
        raise HTTPException(404, "parcel not found")
    return parcel


def _require_reviewable(conn: Connection, parcel_id: UUID, reviewer: dict) -> dict:
    parcel = _require_parcel(conn, parcel_id, for_update=True)
    if parcel["status"] != "PENDING":
        raise HTTPException(409, f"parcel is {parcel['status']}, not PENDING")
    # Separation of duties: nobody reviews a survey they submitted.
    if parcel["submitted_by"] == reviewer["id"]:
        raise HTTPException(403, "you cannot review a parcel you submitted")
    return parcel


def _require_valid(conn: Connection, geometry: PolygonGeometry) -> dict:
    check = repo.check_geometry(conn, geometry.model_dump())
    if not check["valid"]:
        raise HTTPException(422, f"invalid boundary: {check['reason']}")
    return check


@router.post("/parcels/validate", response_model=ValidationResult)
def validate_boundary(geometry: PolygonGeometry, conn: Conn):
    """Dry run: topology, geodetic measures and conflicts, without storing anything."""
    check = repo.check_geometry(conn, geometry.model_dump())
    conflicts = repo.find_conflicts(conn, geojson=geometry.model_dump()) if check["valid"] else []
    return {**check, "conflicts": conflicts}


@router.post("/parcels", response_model=SubmissionResult, status_code=201)
def submit_parcel(sub: ParcelSubmission, conn: Conn, response: Response, user=Surveyor):
    if sub.client_ref and (existing := repo.get_parcel_by_client_ref(conn, sub.client_ref)):
        if existing["submitted_by"] != user["id"]:
            raise HTTPException(409, "client_ref already used by another submission")
        response.status_code = 200
        return {"parcel": existing,
                "conflicts": repo.find_conflicts(conn, parcel_id=existing["id"])}

    _require_valid(conn, sub.boundary)
    accuracies = [p.accuracy_m for p in sub.survey_points if p.accuracy_m is not None]
    try:
        parcel = repo.insert_parcel(conn, sub, max(accuracies) if accuracies else None, user["id"])
    except errors.UniqueViolation as e:
        raise HTTPException(409, f"duplicate: {e.diag.constraint_name}") from e

    conflicts = repo.find_conflicts(conn, parcel_id=parcel["id"])
    repo.record_event(conn, parcel["id"], "SUBMITTED", {
        "conflicts": [{"parcel_id": str(c["parcel_id"]), "overlap_area_sqm": c["overlap_area_sqm"],
                       "blocking": c["blocking"]} for c in conflicts],
    }, user["id"])
    return {"parcel": parcel, "conflicts": conflicts}


@router.get("/parcels")
def list_parcels(conn: Conn,
                 bbox: Annotated[str | None, Query(description="minLon,minLat,maxLon,maxLat")] = None,
                 status: str | None = None,
                 limit: Annotated[int, Query(ge=1, le=5000)] = 1000):
    box = None
    if bbox:
        try:
            box = tuple(float(v) for v in bbox.split(","))
            assert len(box) == 4
        except (ValueError, AssertionError):
            raise HTTPException(422, "bbox must be minLon,minLat,maxLon,maxLat")
    rows = repo.list_parcels(conn, box, status, limit)
    return {"type": "FeatureCollection", "features": [
        {"type": "Feature", "id": str(r["id"]), "geometry": r["boundary"],
         "properties": {k: v for k, v in r.items() if k != "boundary"}}
        for r in rows
    ]}


@router.get("/parcels/extent")
def parcels_extent(conn: Conn):
    """Bounding box [minLon, minLat, maxLon, maxLat] of all parcels, or null when empty."""
    return repo.extent(conn)


@router.get("/parcels/{parcel_id}", response_model=Parcel)
def get_parcel(parcel_id: UUID, conn: Conn):
    return _require_parcel(conn, parcel_id)


@router.get("/parcels/{parcel_id}/conflicts")
def get_conflicts(parcel_id: UUID, conn: Conn):
    _require_parcel(conn, parcel_id)
    return repo.find_conflicts(conn, parcel_id=parcel_id)


@router.post("/parcels/{parcel_id}/approve", response_model=Parcel)
def approve_parcel(parcel_id: UUID, decision: ReviewDecision, conn: Conn, user=Reviewer):
    conn.execute("SELECT pg_advisory_xact_lock(%s)", (APPROVAL_LOCK,))
    parcel = _require_reviewable(conn, parcel_id, user)
    blocking = repo.find_conflicts(conn, parcel_id=parcel_id, statuses=("APPROVED",))
    if blocking:
        raise HTTPException(409, {
            "message": "boundary encroaches on approved parcels",
            "conflicts": [{"parcel_id": str(c["parcel_id"]), "title_deed_no": c["title_deed_no"],
                           "overlap_area_sqm": c["overlap_area_sqm"]} for c in blocking],
        })
    updated = repo.set_status(conn, parcel_id, "APPROVED", decision.note, user["id"])
    repo.record_event(conn, parcel_id, "APPROVED", {"note": decision.note}, user["id"])
    return updated


@router.post("/parcels/{parcel_id}/reject", response_model=Parcel)
def reject_parcel(parcel_id: UUID, decision: ReviewDecision, conn: Conn, user=Reviewer):
    _require_reviewable(conn, parcel_id, user)
    updated = repo.set_status(conn, parcel_id, "REJECTED", decision.note, user["id"])
    repo.record_event(conn, parcel_id, "REJECTED", {"note": decision.note}, user["id"])
    return updated


@router.get("/parcels/{parcel_id}/events")
def get_events(parcel_id: UUID, conn: Conn):
    _require_parcel(conn, parcel_id)
    return repo.list_events(conn, parcel_id)


@router.get("/parcels/{parcel_id}/survey-plan")
def survey_plan(parcel_id: UUID, conn: Conn):
    """Vertex schedule, boundary legs and areas in the grids used on Ghana cadastral plans."""
    parcel = _require_parcel(conn, parcel_id)
    ring = [tuple(p) for p in parcel["boundary"]["coordinates"][0]]
    vertices = ring[:-1]
    lon0, lat0 = vertices[0]
    grids = [geo.GHANA_NATIONAL_GRID, geo.GHANA_METRE_GRID, geo.utm_epsg(lon0, lat0)]
    projected = {epsg: geo.project(vertices, epsg) for epsg in grids}
    return {
        "parcel_id": parcel_id,
        "title_deed_no": parcel["title_deed_no"],
        "owner_name": parcel["owner_name"],
        "crs": [geo.crs_info(e) for e in grids],
        "vertices": [
            {"no": i + 1, "lon": lon, "lat": lat,
             **{f"epsg_{e}": {"x": projected[e][i][0], "y": projected[e][i][1]} for e in grids}}
            for i, (lon, lat) in enumerate(vertices)
        ],
        "legs": geo.boundary_legs(ring),
        "area": geo.area_units(parcel["area_sqm"]),
        "perimeter_m": parcel["perimeter_m"],
    }


@router.get("/tiles/{z}/{x}/{y}.mvt")
def parcel_tile(z: int, x: int, y: int, conn: Conn):
    if not (0 <= z <= 24 and 0 <= x < 2**z and 0 <= y < 2**z):
        raise HTTPException(404, "tile out of range")
    return Response(repo.tile(conn, z, x, y), media_type="application/vnd.mapbox-vector-tile")
