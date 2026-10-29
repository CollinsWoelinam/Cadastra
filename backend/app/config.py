from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
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


settings = Settings()
