"""Coordinate reference systems used by the Ghana cadastre, and geodetic helpers."""

import re
import warnings
from dataclasses import dataclass
from functools import lru_cache

from pyproj import CRS, Geod, Transformer
from pyproj.aoi import AreaOfInterest
from pyproj.transformer import TransformerGroup

from .config import helmert_values, settings

WGS84 = 4326
# Accra / Ghana National Grid — Transverse Mercator in Gold Coast feet, the grid
# used on Lands Commission cadastral plans.
GHANA_NATIONAL_GRID = 2136
# Leigon / Ghana Metre Grid — metric TM on the Leigon datum.
GHANA_METRE_GRID = 25000

# Which configured parameters apply to each grid's datum.
_DATUM_PARAMETERS = {GHANA_NATIONAL_GRID: "accra_to_wgs84", GHANA_METRE_GRID: "leigon_to_wgs84"}
_GHANA_ONSHORE = AreaOfInterest(west_lon_degree=-3.25, south_lat_degree=4.67,
                                east_lon_degree=1.23, north_lat_degree=11.16)

GOLD_COAST_FOOT_M = 0.3047997101815088

SQM_PER_ACRE = 4046.8564224
SQM_PER_HECTARE = 10_000.0

_geod = Geod(ellps="WGS84")


def utm_epsg(lon: float, lat: float) -> int:
    zone = int((lon + 180) // 6) + 1
    return (32600 if lat >= 0 else 32700) + zone


@dataclass(frozen=True)
class GridTransform:
    transformer: Transformer
    description: str
    # Stated accuracy of the datum change; None where there is none (UTM is on WGS 84).
    accuracy_m: float | None
    source: str


@lru_cache(maxsize=32)
def grid_transform(dst_epsg: int) -> GridTransform:
    """The WGS 84 → grid transformation used for survey plans, fixed per grid."""
    if CRS.from_epsg(dst_epsg).geodetic_crs.equals(CRS.from_epsg(WGS84)):
        return GridTransform(Transformer.from_crs(WGS84, dst_epsg, always_xy=True),
                             "No datum change (WGS 84)", None, "WGS 84")

    parameters = getattr(settings, _DATUM_PARAMETERS.get(dst_epsg, ""), None)
    if parameters:
        dx, dy, dz, rx, ry, rz, ds = helmert_values(parameters)
        if settings.datum_rotation_convention == "coordinate_frame":
            rx, ry, rz = -rx, -ry, -rz  # PROJ's +towgs84 takes position-vector rotations
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")  # to_proj4() warns that it is lossy in general
            base = re.sub(r"\s*\+towgs84=\S+", "", CRS.from_epsg(dst_epsg).to_proj4())
        towgs84 = ",".join(repr(v) for v in (dx, dy, dz, rx, ry, rz, ds))
        target = CRS.from_proj4(f"{base} +towgs84={towgs84}")
        kind = "7-parameter" if any((rx, ry, rz, ds)) else "3-parameter"
        return GridTransform(Transformer.from_crs(WGS84, target, always_xy=True),
                             f"Configured {kind} transformation",
                             settings.datum_parameters_accuracy_m, settings.datum_parameters_source)

    # Left to itself PROJ picks among several operations per point at transform time;
    # pin the most accurate one valid onshore so every plan uses the same one.
    candidates = TransformerGroup(WGS84, dst_epsg, always_xy=True, area_of_interest=_GHANA_ONSHORE).transformers
    best = min(candidates, key=lambda t: t.accuracy if t.accuracy > 0 else float("inf"))
    return GridTransform(best, best.description, best.accuracy if best.accuracy > 0 else None, "EPSG")


def project(points: list[tuple[float, float]], dst_epsg: int) -> list[tuple[float, float]]:
    t = grid_transform(dst_epsg).transformer
    xs, ys = t.transform([p[0] for p in points], [p[1] for p in points])
    return list(zip(xs, ys))


def crs_info(epsg: int) -> dict:
    crs = CRS.from_epsg(epsg)
    t = grid_transform(epsg)
    return {"epsg": epsg, "name": crs.name, "unit": crs.axis_info[0].unit_name,
            "transformation": {"description": t.description, "accuracy_m": t.accuracy_m, "source": t.source}}


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
