from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

Position = tuple[float, float]


class PolygonGeometry(BaseModel):
    type: Literal["Polygon"]
    coordinates: list[list[Position]]

    @field_validator("coordinates")
    @classmethod
    def check_rings(cls, rings: list[list[Position]]) -> list[list[Position]]:
        if not rings:
            raise ValueError("polygon needs an exterior ring")
        closed = []
        for ring in rings:
            for lon, lat in ring:
                if not (-180 <= lon <= 180 and -90 <= lat <= 90):
                    raise ValueError(f"position ({lon}, {lat}) is outside lon/lat range")
            if ring and ring[0] != ring[-1]:
                ring = [*ring, ring[0]]
            if len(ring) < 4:
                raise ValueError("each ring needs at least 3 distinct vertices")
            closed.append(ring)
        return closed


class SurveyPoint(BaseModel):
    lon: float = Field(ge=-180, le=180)
    lat: float = Field(ge=-90, le=90)
    accuracy_m: float | None = Field(default=None, ge=0)
    captured_at: datetime | None = None


class ParcelSubmission(BaseModel):
    client_ref: UUID | None = None
    title_deed_no: str = Field(min_length=1, max_length=50)
    owner_name: str = Field(min_length=1, max_length=100)
    boundary: PolygonGeometry
    survey_points: list[SurveyPoint] = []


class ReviewDecision(BaseModel):
    note: str | None = None


class Conflict(BaseModel):
    parcel_id: UUID
    title_deed_no: str
    owner_name: str
    status: str
    overlap_area_sqm: float
    overlap_geometry: dict
    # True when the other parcel is APPROVED: this submission cannot be approved.
    blocking: bool


class ValidationResult(BaseModel):
    valid: bool
    reason: str | None
    area_sqm: float | None
    perimeter_m: float | None
    conflicts: list[Conflict]


class Parcel(BaseModel):
    id: UUID
    client_ref: UUID | None
    title_deed_no: str
    owner_name: str
    boundary: dict
    area_sqm: float
    perimeter_m: float
    survey_accuracy_m: float | None
    status: str
    review_note: str | None
    reviewed_at: datetime | None
    created_at: datetime


class SubmissionResult(BaseModel):
    parcel: Parcel
    conflicts: list[Conflict]
