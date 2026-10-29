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
    submitted_by: UUID | None
    submitted_by_name: str | None
    reviewed_by: UUID | None
    reviewed_by_name: str | None


class SubmissionResult(BaseModel):
    parcel: Parcel
    conflicts: list[Conflict]


Role = Literal["SURVEYOR", "REVIEWER", "ADMIN"]


class User(BaseModel):
    id: UUID
    email: str
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime
    # Last sign-in or session refresh; only filled in the admin user list.
    last_active_at: datetime | None = None


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    access_expires_at: datetime
    refresh_token: str
    refresh_expires_at: datetime
    token_type: Literal["bearer"] = "bearer"
    user: User


class UserCreate(BaseModel):
    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$", max_length=254)
    full_name: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=12, max_length=128)
    role: Role


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=100)
    role: Role | None = None
    is_active: bool | None = None
    password: str | None = Field(default=None, min_length=12, max_length=128)


class PasswordChange(BaseModel):
    current_password: str = Field(max_length=128)
    new_password: str = Field(min_length=12, max_length=128)
