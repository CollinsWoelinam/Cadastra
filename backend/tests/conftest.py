import os
import uuid

import psycopg
import pytest

ADMIN_URL = os.environ.get("DATABASE_URL", "postgresql://cadastra:cadastra@localhost:5433/cadastra")
TEST_DB = "cadastra_test"
TEST_URL = ADMIN_URL.rsplit("/", 1)[0] + f"/{TEST_DB}"
os.environ["DATABASE_URL"] = TEST_URL

from fastapi.testclient import TestClient  # noqa: E402
from pyproj import Transformer  # noqa: E402

from app.main import app  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def test_database():
    with psycopg.connect(ADMIN_URL, autocommit=True) as conn:
        conn.execute(f"DROP DATABASE IF EXISTS {TEST_DB} WITH (FORCE)")
        conn.execute(f"CREATE DATABASE {TEST_DB}")
    yield


@pytest.fixture(scope="session")
def client(test_database):
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def clean_tables(client):
    yield
    with psycopg.connect(TEST_URL, autocommit=True) as conn:
        conn.execute("ALTER TABLE parcel_events DISABLE TRIGGER parcel_events_append_only")
        conn.execute("TRUNCATE parcel_events, survey_points, parcels")
        conn.execute("ALTER TABLE parcel_events ENABLE TRIGGER parcel_events_append_only")


# Squares are laid out in UTM 30N metres around Accra so sizes are exact on the ground.
_from_utm = Transformer.from_crs(32630, 4326, always_xy=True)
ORIGIN_E, ORIGIN_N = 806_000.0, 620_000.0


def square(x: float, y: float, size: float) -> dict:
    corners = [(x, y), (x + size, y), (x + size, y + size), (x, y + size), (x, y)]
    return {"type": "Polygon", "coordinates": [[
        list(_from_utm.transform(ORIGIN_E + cx, ORIGIN_N + cy)) for cx, cy in corners
    ]]}


@pytest.fixture
def submit(client):
    def _submit(boundary: dict, **overrides):
        body = {"title_deed_no": f"GA-{uuid.uuid4().hex[:8]}", "owner_name": "Ama Mensah",
                "boundary": boundary, **overrides}
        return client.post("/parcels", json=body)
    return _submit


@pytest.fixture
def approved(client, submit):
    def _approved(boundary: dict) -> dict:
        r = submit(boundary)
        assert r.status_code == 201, r.text
        pid = r.json()["parcel"]["id"]
        r = client.post(f"/parcels/{pid}/approve", json={})
        assert r.status_code == 200, r.text
        return r.json()
    return _approved
