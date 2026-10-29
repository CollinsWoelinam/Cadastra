from pathlib import Path

import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from .config import settings

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "migrations"

pool = ConnectionPool(settings.database_url, open=False, kwargs={"row_factory": dict_row})


def migrate(conninfo: str) -> None:
    """Apply any migrations/*.sql files not yet recorded, in filename order."""
    with psycopg.connect(conninfo, autocommit=True) as conn:
        conn.execute("CREATE TABLE IF NOT EXISTS schema_migrations (name TEXT PRIMARY KEY)")
        # Serialise concurrent app instances applying migrations.
        conn.execute("SELECT pg_advisory_lock(727001)")
        try:
            applied = {r[0] for r in conn.execute("SELECT name FROM schema_migrations")}
            for path in sorted(MIGRATIONS_DIR.glob("*.sql")):
                if path.name in applied:
                    continue
                with conn.transaction():
                    conn.execute(path.read_text())
                    conn.execute("INSERT INTO schema_migrations (name) VALUES (%s)", (path.name,))
        finally:
            conn.execute("SELECT pg_advisory_unlock(727001)")
