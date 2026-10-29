import math
import uuid

import psycopg
import pytest

from .conftest import TEST_URL, square


def test_geodetic_area_and_perimeter(client):
    r = client.post("/parcels/validate", json=square(0, 0, 100))
    body = r.json()
    assert body["valid"] is True
    # UTM scale distortion near Accra is < 0.1%, so a 100 m UTM square is ~1 ha on the ground.
    assert body["area_sqm"] == pytest.approx(10_000, rel=2e-3)
    assert body["perimeter_m"] == pytest.approx(400, rel=1e-3)


def test_self_intersecting_boundary_rejected(client, submit):
    bowtie = square(0, 0, 100)
    c = bowtie["coordinates"][0]
    bowtie["coordinates"] = [[c[0], c[2], c[1], c[3], c[0]]]
    assert client.post("/parcels/validate", json=bowtie).json()["valid"] is False
    r = submit(bowtie)
    assert r.status_code == 422
    assert "Self-intersection" in r.json()["detail"]


def test_unclosed_ring_is_closed(submit):
    poly = square(0, 0, 50)
    poly["coordinates"][0] = poly["coordinates"][0][:-1]
    assert submit(poly).status_code == 201


def test_partial_overlap_is_measured(approved, submit):
    approved(square(0, 0, 100))
    r = submit(square(90, 0, 100))  # 10 m x 100 m strip shared
    conflicts = r.json()["conflicts"]
    assert len(conflicts) == 1
    assert conflicts[0]["blocking"] is True
    assert conflicts[0]["overlap_area_sqm"] == pytest.approx(1_000, rel=2e-3)
    assert conflicts[0]["overlap_geometry"]["type"] == "Polygon"


def test_contained_parcel_is_a_conflict(approved, submit):
    # ST_Overlaps returns false for containment; the interior-intersects test must not.
    approved(square(0, 0, 100))
    conflicts = submit(square(25, 25, 20)).json()["conflicts"]
    assert len(conflicts) == 1
    assert conflicts[0]["overlap_area_sqm"] == pytest.approx(400, rel=2e-3)


def test_identical_boundary_is_a_conflict(approved, submit):
    approved(square(0, 0, 100))
    assert len(submit(square(0, 0, 100)).json()["conflicts"]) == 1


def test_shared_edge_is_not_a_conflict(approved, submit):
    approved(square(0, 0, 100))
    assert submit(square(100, 0, 100)).json()["conflicts"] == []


def test_grid_of_adjacent_parcels_can_all_be_approved(approved):
    # Regression: comparing via rounded GeoJSON turned shared edges into ~1 cm² overlaps.
    for col in range(4):
        for row in range(4):
            approved(square(col * 30, row * 30, 30))


def test_pending_overlap_is_non_blocking_warning(submit):
    submit(square(0, 0, 100))
    conflicts = submit(square(50, 0, 100)).json()["conflicts"]
    assert [c["blocking"] for c in conflicts] == [False]


def test_second_of_two_overlapping_pending_cannot_be_approved(client, submit):
    a = submit(square(0, 0, 100)).json()["parcel"]["id"]
    b = submit(square(50, 0, 100)).json()["parcel"]["id"]
    assert client.post(f"/parcels/{a}/approve", json={}).status_code == 200
    r = client.post(f"/parcels/{b}/approve", json={})
    assert r.status_code == 409
    assert r.json()["detail"]["conflicts"][0]["parcel_id"] == a


def test_review_only_from_pending(client, submit):
    pid = submit(square(0, 0, 10)).json()["parcel"]["id"]
    assert client.post(f"/parcels/{pid}/reject", json={"note": "bad survey"}).status_code == 200
    assert client.post(f"/parcels/{pid}/approve", json={}).status_code == 409
    assert client.get(f"/parcels/{pid}").json()["review_note"] == "bad survey"


def test_client_ref_makes_upload_idempotent(submit):
    ref = str(uuid.uuid4())
    first = submit(square(0, 0, 10), client_ref=ref, title_deed_no="GA-1")
    retry = submit(square(0, 0, 10), client_ref=ref, title_deed_no="GA-1")
    assert first.status_code == 201
    assert retry.status_code == 200
    assert retry.json()["parcel"]["id"] == first.json()["parcel"]["id"]


def test_duplicate_title_deed(submit):
    assert submit(square(0, 0, 10), title_deed_no="GA-DUP").status_code == 201
    assert submit(square(500, 0, 10), title_deed_no="GA-DUP").status_code == 409


def test_survey_points_stored_and_accuracy_recorded(submit):
    poly = square(0, 0, 10)
    points = [{"lon": lon, "lat": lat, "accuracy_m": acc}
              for (lon, lat), acc in zip(poly["coordinates"][0][:-1], [0.02, 0.03, 0.05, 0.02])]
    parcel = submit(poly, survey_points=points).json()["parcel"]
    assert parcel["survey_accuracy_m"] == 0.05
    with psycopg.connect(TEST_URL) as conn:
        n = conn.execute("SELECT count(*) FROM survey_points WHERE parcel_id = %s",
                         (parcel["id"],)).fetchone()[0]
    assert n == 4


def test_audit_trail_is_append_only(client, submit):
    pid = submit(square(0, 0, 10)).json()["parcel"]["id"]
    client.post(f"/parcels/{pid}/approve", json={"note": "ok"})
    events = client.get(f"/parcels/{pid}/events").json()
    assert [e["event_type"] for e in events] == ["SUBMITTED", "APPROVED"]
    with psycopg.connect(TEST_URL) as conn, pytest.raises(psycopg.errors.RaiseException):
        conn.execute("DELETE FROM parcel_events")


def test_bbox_listing(submit, client):
    submit(square(0, 0, 10))
    submit(square(5_000, 5_000, 10))
    near = square(-1, -1, 12)["coordinates"][0]
    lons, lats = [p[0] for p in near], [p[1] for p in near]
    bbox = f"{min(lons)},{min(lats)},{max(lons)},{max(lats)}"
    fc = client.get("/parcels", params={"bbox": bbox}).json()
    assert len(fc["features"]) == 1


def test_extent(client, submit):
    assert client.get("/parcels/extent").json() is None
    poly = square(0, 0, 100)
    submit(poly)
    minx, miny, maxx, maxy = client.get("/parcels/extent").json()
    lons, lats = [p[0] for p in poly["coordinates"][0]], [p[1] for p in poly["coordinates"][0]]
    assert (minx, maxx) == pytest.approx((min(lons), max(lons)))
    assert (miny, maxy) == pytest.approx((min(lats), max(lats)))


def test_survey_plan_in_ghana_grids(client, submit):
    pid = submit(square(0, 0, 100)).json()["parcel"]["id"]
    plan = client.get(f"/parcels/{pid}/survey-plan").json()
    assert [c["epsg"] for c in plan["crs"]] == [2136, 25000, 32630]
    v = plan["vertices"][0]
    # Accra in Ghana National Grid (Gold Coast feet): ~1.19M E, ~0.33M N.
    assert 1_100_000 < v["epsg_2136"]["x"] < 1_300_000
    assert 250_000 < v["epsg_2136"]["y"] < 400_000
    assert len(plan["legs"]) == 4
    assert sum(l["length_m"] for l in plan["legs"]) == pytest.approx(plan["perimeter_m"], rel=1e-6)
    assert plan["legs"][0]["bearing_deg"] == pytest.approx(90, abs=2)  # first leg runs east
    assert plan["area"]["acres"] == pytest.approx(2.471, rel=3e-3)


def _tile_for(lon: float, lat: float, z: int) -> tuple[int, int]:
    n = 2 ** z
    y = (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n
    return int((lon + 180) / 360 * n), int(y)


def test_vector_tile(client, submit):
    poly = square(0, 0, 100)
    submit(poly)
    x, y = _tile_for(*poly["coordinates"][0][0], 14)
    r = client.get(f"/tiles/14/{x}/{y}.mvt")
    assert r.status_code == 200
    assert r.headers["content-type"] == "application/vnd.mapbox-vector-tile"
    assert b"parcels" in r.content
    assert client.get(f"/tiles/14/{x + 50}/{y}.mvt").content == b""
