from typing import Literal

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def helmert_values(text: str) -> tuple[float, ...]:
    """Parses "dx,dy,dz" or "dx,dy,dz,rx,ry,rz,ds" into seven values (missing ones zero)."""
    values = tuple(float(v) for v in text.split(","))
    if len(values) not in (3, 7):
        raise ValueError(f"expected 3 or 7 comma-separated numbers, got {len(values)}: {text!r}")
    return values + (0.0,) * (7 - len(values))


class Settings(BaseSettings):
    # Compose passes unset variables through as empty strings; treat those as unset.
    model_config = SettingsConfigDict(env_ignore_empty=True)

    database_url: str = "postgresql://cadastra:cadastra@localhost:5433/cadastra"
    # Overlaps smaller than this (m²) are not treated as conflicts. Default 0 flags
    # everything; raise it to absorb GNSS noise along shared boundaries.
    overlap_tolerance_sqm: float = 0.0

    # HMAC key for access tokens. Required: there is deliberately no default.
    jwt_secret: str = Field(min_length=32)
    access_token_ttl_minutes: int = 15
    refresh_token_ttl_days: int = 30

    # Sign-in throttling: failures within the window, per email and per client IP.
    # A success clears the email's count; the IP limit is looser because field crews
    # often share one carrier or office address.
    login_window_minutes: int = 15
    login_max_failures_per_email: int = 10
    login_max_failures_per_ip: int = 100

    # Local datum parameters from the Survey and Mapping Division for the grid
    # coordinates on survey plans, exactly as published: from the local datum TO
    # WGS 84, "dx,dy,dz" (metres) or "dx,dy,dz,rx,ry,rz,ds" (metres, arc-seconds,
    # ppm). Unset, the EPSG transformations are used (Accra ±6 m, Leigon ±5 m).
    accra_to_wgs84: str | None = None
    leigon_to_wgs84: str | None = None
    # Published 7-parameter sets use either convention, and mixing them up rotates
    # every coordinate the wrong way, so it must be stated whenever rotations are given.
    datum_rotation_convention: Literal["position_vector", "coordinate_frame"] | None = None
    # Printed on survey plans; required with custom parameters.
    datum_parameters_source: str | None = None
    datum_parameters_accuracy_m: float | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def _check_datum_parameters(self):
        given = [p for p in (self.accra_to_wgs84, self.leigon_to_wgs84) if p]
        for p in given:
            if any(helmert_values(p)[3:6]) and self.datum_rotation_convention is None:
                raise ValueError("datum parameters include rotations: set DATUM_ROTATION_CONVENTION")
        if given and (not self.datum_parameters_source or self.datum_parameters_accuracy_m is None):
            raise ValueError("custom datum parameters need DATUM_PARAMETERS_SOURCE and DATUM_PARAMETERS_ACCURACY_M")
        return self


settings = Settings()
