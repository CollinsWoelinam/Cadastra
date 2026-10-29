from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://cadastra:cadastra@localhost:5433/cadastra"
    # Overlaps smaller than this (m²) are not treated as conflicts. Default 0 flags
    # everything; raise it to absorb GNSS noise along shared boundaries.
    overlap_tolerance_sqm: float = 0.0


settings = Settings()
