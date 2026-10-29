"""Coordinate reference systems used by the Ghana cadastre, and geodetic helpers."""

from functools import lru_cache

from pyproj import CRS, Geod, Transformer

WGS84 = 4326
# Accra / Ghana National Grid — Transverse Mercator in Gold Coast feet, the grid
# used on Lands Commission cadastral plans.
GHANA_NATIONAL_GRID = 2136
# Leigon / Ghana Metre Grid — metric TM on the Leigon datum.
# Note: the stock EPSG WGS84→Accra/Leigon transformations are only good to ~5–6 m.
GHANA_METRE_GRID = 25000

GOLD_COAST_FOOT_M = 0.3047997101815088

SQM_PER_ACRE = 4046.8564224
SQM_PER_HECTARE = 10_000.0

_geod = Geod(ellps="WGS84")


def utm_epsg(lon: float, lat: float) -> int:
    zone = int((lon + 180) // 6) + 1
    return (32600 if lat >= 0 else 32700) + zone


@lru_cache(maxsize=32)
def _transformer(dst_epsg: int) -> Transformer:
    return Transformer.from_crs(WGS84, dst_epsg, always_xy=True)


def project(points: list[tuple[float, float]], dst_epsg: int) -> list[tuple[float, float]]:
    t = _transformer(dst_epsg)
    xs, ys = t.transform([p[0] for p in points], [p[1] for p in points])
    return list(zip(xs, ys))


def crs_info(epsg: int) -> dict:
    crs = CRS.from_epsg(epsg)
    return {"epsg": epsg, "name": crs.name, "unit": crs.axis_info[0].unit_name}


def boundary_legs(ring: list[tuple[float, float]]) -> list[dict]:
    """Geodesic length and forward azimuth (true north, 0–360°) of each boundary leg."""
    legs = []
    for i in range(len(ring) - 1):
        (lon1, lat1), (lon2, lat2) = ring[i], ring[i + 1]
        az, _, dist = _geod.inv(lon1, lat1, lon2, lat2)
        legs.append({"from": i + 1, "to": (i + 1) % (len(ring) - 1) + 1,
                     "bearing_deg": az % 360, "length_m": dist})
    return legs


def area_units(area_sqm: float) -> dict:
    return {
        "sqm": area_sqm,
        "hectares": area_sqm / SQM_PER_HECTARE,
        "acres": area_sqm / SQM_PER_ACRE,
    }
