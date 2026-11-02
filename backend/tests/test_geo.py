import math

import pytest
from pydantic import ValidationError
from pyproj import Transformer

from app import geo
from app.config import Settings, settings

from .conftest import square

# Accra, Tema and Kumasi.
POINTS = [(-0.1708, 5.6230), (-0.0166, 5.6698), (-1.6244, 6.6885)]
FT = geo.GOLD_COAST_FOOT_M
DATUM_FIELDS = ("accra_to_wgs84", "leigon_to_wgs84", "datum_rotation_convention",
                "datum_parameters_source", "datum_parameters_accuracy_m")


@pytest.fixture
def datum():
    saved = {f: getattr(settings, f) for f in DATUM_FIELDS}

    def configure(**values):
        values.setdefault("datum_parameters_source", "Survey and Mapping Division (test)")
        values.setdefault("datum_parameters_accuracy_m", 0.5)
        for field, value in values.items():
            setattr(settings, field, value)
        geo.grid_transform.cache_clear()

    yield configure
    for field, value in saved.items():
        setattr(settings, field, value)
    geo.grid_transform.cache_clear()


def _shift(a, b):
    return max(math.dist(p, q) for p, q in zip(a, b))


def test_default_pins_the_most_accurate_onshore_operation():
    gng, gmg = geo.grid_transform(geo.GHANA_NATIONAL_GRID), geo.grid_transform(geo.GHANA_METRE_GRID)
    assert (gng.accuracy_m, gng.source) == (6.0, "EPSG")
    assert "Accra to WGS 84 (4)" in gng.description
    assert (gmg.accuracy_m, gmg.source) == (5.0, "EPSG")
    assert geo.grid_transform(32630).accuracy_m is None


def test_configured_epsg_values_reproduce_the_default(datum):
    # EPSG "Accra to WGS 84 (4)" and "Leigon to WGS 84 (1)", entered as published.
    before = {e: geo.project(POINTS, e) for e in (geo.GHANA_NATIONAL_GRID, geo.GHANA_METRE_GRID)}
    datum(accra_to_wgs84="-170,33,326", leigon_to_wgs84="-130,29,364")
    assert geo.grid_transform(geo.GHANA_NATIONAL_GRID).source == "Survey and Mapping Division (test)"
    assert _shift(before[geo.GHANA_NATIONAL_GRID], geo.project(POINTS, geo.GHANA_NATIONAL_GRID)) * FT < 0.001
    assert _shift(before[geo.GHANA_METRE_GRID], geo.project(POINTS, geo.GHANA_METRE_GRID)) < 0.001


def test_a_one_metre_shift_moves_grid_coordinates_about_a_metre(datum):
    # Geocentric Y points almost due east in Ghana (X is nearly vertical there, so a
    # change in dx mostly changes height).
    datum(accra_to_wgs84="-170,33,326")
    a = geo.project(POINTS, geo.GHANA_NATIONAL_GRID)
    datum(accra_to_wgs84="-170,34,326")
    b = geo.project(POINTS, geo.GHANA_NATIONAL_GRID)
    assert _shift(a, b) * FT == pytest.approx(1.0, abs=0.05)


def test_rotation_conventions_match_proj(datum):
    # Independent reference: PROJ's own Helmert step with an explicit convention.
    reference = Transformer.from_pipeline(
        "+proj=pipeline +step +proj=unitconvert +xy_in=deg +xy_out=rad +step +proj=push +v_3 "
        "+step +proj=cart +ellps=WGS84 "
        "+step +inv +proj=helmert +x=-171.16 +y=17.29 +z=325.21 +rx=0.2 +ry=-0.1 +rz=0.814 +s=-0.38 "
        "+convention=coordinate_frame "
        "+step +inv +proj=cart +a=6378300 +rf=296 +step +proj=pop +v_3 "
        "+step +proj=tmerc +lat_0=4.66666666666667 +lon_0=-1 +k=0.99975 +x_0=274319.739163358 +y_0=0 "
        "+a=6378300 +rf=296")
    expected = [(x / FT, y / FT) for x, y in zip(*reference.transform(*zip(*POINTS)))]

    datum(accra_to_wgs84="-171.16,17.29,325.21,0.2,-0.1,0.814,-0.38", datum_rotation_convention="coordinate_frame")
    cf = geo.project(POINTS, geo.GHANA_NATIONAL_GRID)
    assert _shift(cf, expected) * FT < 0.001
    assert "7-parameter" in geo.grid_transform(geo.GHANA_NATIONAL_GRID).description

    # The same numbers read as position-vector rotations land tens of metres away.
    datum(accra_to_wgs84="-171.16,17.29,325.21,0.2,-0.1,0.814,-0.38", datum_rotation_convention="position_vector")
    assert _shift(geo.project(POINTS, geo.GHANA_NATIONAL_GRID), cf) * FT > 10


@pytest.mark.parametrize("values, message", [
    ({"accra_to_wgs84": "1,2"}, "3 or 7"),
    ({"accra_to_wgs84": "-170,33,326,0,0,0.5,0", "datum_parameters_source": "SMD",
      "datum_parameters_accuracy_m": 0.5}, "DATUM_ROTATION_CONVENTION"),
    ({"leigon_to_wgs84": "-130,29,364"}, "DATUM_PARAMETERS_SOURCE"),
])
def test_incomplete_datum_settings_are_refused_at_startup(values, message):
    with pytest.raises(ValidationError, match=message):
        Settings(jwt_secret="x" * 32, **values)


def test_survey_plan_states_the_transformation(client, submit, datum):
    pid = submit(square(0, 0, 50)).json()["parcel"]["id"]
    crs = {c["epsg"]: c["transformation"] for c in client.get(f"/parcels/{pid}/survey-plan").json()["crs"]}
    assert crs[2136] == {"description": geo.grid_transform(2136).description, "accuracy_m": 6.0, "source": "EPSG"}
    assert crs[32630]["accuracy_m"] is None

    datum(accra_to_wgs84="-170,33,326", datum_parameters_accuracy_m=0.3)
    crs = {c["epsg"]: c["transformation"] for c in client.get(f"/parcels/{pid}/survey-plan").json()["crs"]}
    assert crs[2136]["accuracy_m"] == 0.3
    assert crs[2136]["source"] == "Survey and Mapping Division (test)"
    assert crs[25000]["source"] == "EPSG"  # Leigon parameters not given
