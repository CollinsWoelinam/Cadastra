"""Seed demo parcels around East Legon, Accra. Run: docker compose run --rm api python -m scripts.seed"""

import json
import os
import urllib.error
import urllib.request

from pyproj import Transformer

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


def call(method: str, path: str, body: dict | None = None) -> tuple[int, dict]:
    req = urllib.request.Request(f"{API}{path}", method=method,
                                 data=json.dumps(body or {}).encode(),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def submit(deed: str, owner: str, boundary: dict, approve: bool) -> None:
    status, body = call("POST", "/parcels", {"title_deed_no": deed, "owner_name": owner,
                                             "boundary": boundary})
    if status == 409:
        print(f"skip {deed}: already exists")
        return
    assert status == 201, body
    if approve:
        status, body = call("POST", f"/parcels/{body['parcel']['id']}/approve", {})
        assert status == 200, body
    print(f"{'approved' if approve else 'pending '} {deed}")


def main() -> None:
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
