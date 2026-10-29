from contextlib import asynccontextmanager

from fastapi import FastAPI

from .config import settings
from .db import migrate, pool
from .routes import parcels


@asynccontextmanager
async def lifespan(_: FastAPI):
    migrate(settings.database_url)
    pool.open(wait=True)
    yield
    pool.close()


app = FastAPI(title="Cadastra Core Engine", lifespan=lifespan)
app.include_router(parcels.router)


@app.get("/health")
def health():
    with pool.connection() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok"}
