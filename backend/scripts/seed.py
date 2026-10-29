"""DEV ONLY: seed demo accounts and parcels around East Legon, Accra.

    docker compose run --rm api python -m scripts.seed

Creates three accounts sharing DEV_PASSWORD. Never run this against a real registry.
"""

import json
import os
import urllib.error
import urllib.request

import psycopg
from psycopg.rows import dict_row
from pyproj import Transformer

from app.auth import create_user
from app.config import settings

DEV_PASSWORD = "cadastra-dev-password"
DEV_USERS = [
    ("admin@cadastra.local", "Dev Admin", "ADMIN"),
    ("surveyor@cadastra.local", "Kojo Surveyor", "SURVEYOR"),
    ("reviewer@cadastra.local", "Abena Reviewer", "REVIEWER"),
]

API = os.environ.get("CORE_API_URL", "http://api:8000")
_from_utm = Transformer.from_crs(32630, 4326, always_xy=True)
# UTM 30N origin near East Legon, Accra.
ORIGIN_E, ORIGIN_N = 813_400.0, 622_300.0

OWNERS = ["Kwame Asante", "Ama Mensah", "Kofi Boateng", "Akosua Owusu", "Yaw Darko",
          "Efua Addo", "Kojo Appiah", "Abena Osei", "Kwesi Agyeman", "Adwoa Tetteh"]


def plot(x: float, y: float, w: float, h: float) -> dict:
    corners = [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]
    return {"type": "Polygon", "coordinates": [[
        list(_from_utm.transform(ORIGIN_E + cx, ORIGIN_N + cy)) for cx, cy in corners
    ]]}


def ensure_dev_users() -> None:
    with psycopg.connect(settings.database_url, row_factory=dict_row) as conn:
        for email, name, role in DEV_USERS:
            if conn.execute("SELECT 1 FROM users WHERE lower(email) = %s", (email,)).fetchone() is None:
                create_user(conn, email, name, DEV_PASSWORD, role)
                print(f"created dev {role} {email}")


def login(email: str) -> str:
    status, body = call("POST", "/auth/login", {"email": email, "password": DEV_PASSWORD})
    assert status == 200, body
    return body["access_token"]


TOKENS: dict[str, str] = {}


def call(method: str, path: str, body: dict | None = None, as_user: str | None = None) -> tuple[int, dict]:
    headers = {"Content-Type": "application/json"}
    if as_user:
        headers["Authorization"] = f"Bearer {TOKENS[as_user]}"
    req = urllib.request.Request(f"{API}{path}", method=method,
                                 data=json.dumps(body or {}).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def submit(deed: str, owner: str, boundary: dict, approve: bool) -> None:
    status, body = call("POST", "/parcels", {"title_deed_no": deed, "owner_name": owner,
                                             "boundary": boundary}, as_user="surveyor")
    if status == 409:
        print(f"skip {deed}: already exists")
        return
    assert status == 201, body
    if approve:
        status, body = call("POST", f"/parcels/{body['parcel']['id']}/approve", {}, as_user="reviewer")
        assert status == 200, body
    print(f"{'approved' if approve else 'pending '} {deed}")


def main() -> None:
    ensure_dev_users()
    TOKENS["surveyor"] = login("surveyor@cadastra.local")
    TOKENS["reviewer"] = login("reviewer@cadastra.local")
    # 6 x 5 block of 30 m x 36 m plots with a 12 m road every two columns.
    n = 0
    for col in range(6):
        for row in range(5):
            x = col * 30 + (col // 2) * 12
            submit(f"GA/EL/{1000 + n}", OWNERS[n % len(OWNERS)], plot(x, row * 36, 30, 36), True)
            n += 1

    # Pending surveys that exercise the inspector.
    submit("GA/EL/2001", "Nana Ofori", plot(52, 20, 30, 36), False)        # straddles two plots
    submit("GA/EL/2002", "Esi Quaye", plot(5, 5, 15, 15), False)           # inside an approved plot
    submit("GA/EL/2003", "Kwabena Nti", plot(0, 180, 30, 36), False)       # shares an edge only: clean
    submit("GA/EL/2004", "Afia Sarpong", plot(-0.4, 216, 30, 36), False)   # 0.4 m GNSS sliver vs 2005
    submit("GA/EL/2005", "Yaa Badu", plot(29.4, 216, 30, 36), False)


if __name__ == "__main__":
    main()
    print(f"\nDev accounts ({DEV_PASSWORD}): " + ", ".join(e for e, _, _ in DEV_USERS))
