"""Vespera FastAPI application entry point.

Production rules (VSP-013):
- CORS middleware registered before all routers.
- ALLOWED_ORIGINS read from env; defaults to localhost for dev.
- Secrets come from env only — never hardcoded.
- Structured JSON logging via app.infrastructure.logging_config.
- /health returns a machine-readable payload including catalog state
  and DB reachability — suitable for a free-tier host readiness check.
- Catalog is indexed on startup; failures are logged but do not block boot.
"""

from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import case, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.middleware.cors import CORSMiddleware

# Load .env before any app imports that read settings
load_dotenv()

from app.api.auth import router as auth_router          # noqa: E402
from app.api.catalog import router as catalog_router    # noqa: E402
from app.api.events import router as events_router      # noqa: E402
from app.api.sessions import router as sessions_router  # noqa: E402
from app.api.traces import router as traces_router      # noqa: E402
from app.api.twilight import router as twilight_router  # noqa: E402
from app.infrastructure.database import get_db, init_db  # noqa: E402
from app.infrastructure.models import CatalogTrackIndex  # noqa: E402
from app.api.feeds import router as feeds_router        # noqa: E402

log = logging.getLogger("vespera")


# ── Startup / shutdown ────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(_app: FastAPI):
    # 1. Create DB tables (no-op when Alembic has already run them)
    await init_db()

    # 2. Index catalog so retrieval uses SQL immediately
    from app.infrastructure.database import AsyncSessionLocal
    from app.domain.retrieval.indexer import index_catalog
    async with AsyncSessionLocal() as session:
        try:
            count = await index_catalog(session)
            await session.commit()
            if count:
                log.info("Catalog indexed at startup: %d tracks.", count)
        except Exception as exc:
            log.warning("Catalog index failed at startup: %s", exc)

    yield


# ── App factory ───────────────────────────────────────────────────────────────

def create_app() -> FastAPI:
    application = FastAPI(
        title="Vespera AI Music Discovery",
        version="0.12.0",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # CORS — must be added BEFORE routers so it applies to all routes
    _allowed = [o.strip() for o in os.environ.get(
        "ALLOWED_ORIGINS", "http://localhost:8080,http://localhost:3000"
    ).split(",") if o.strip()]
    application.add_middleware(
        CORSMiddleware,
        allow_origins=_allowed,
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=["*"],
    )

    # VSP-007 → VSP-012 routers
    application.include_router(catalog_router, prefix="/api/v1")
    application.include_router(auth_router,    prefix="/api/v1")
    application.include_router(events_router,  prefix="/api/v1")
    application.include_router(twilight_router, prefix="/api/v1")
    application.include_router(traces_router,  prefix="/api/v1")
    application.include_router(sessions_router, prefix="/api/v1")

    # Legacy home/explore/search endpoints (pre-VSP-003 Spotify/YT feeds)
    application.include_router(feeds_router, prefix="/api/v1")

    return application


app = create_app()


# ── Health endpoint ───────────────────────────────────────────────────────────

@app.get("/health", tags=["ops"])
async def health(db: AsyncSession = Depends(get_db)) -> JSONResponse:
    """Readiness check: 200 when the DB answers, 503 when it does not.

    catalog_tracks=0 is not an error: the catalog has simply not been loaded.
    """
    try:
        await db.execute(text("SELECT 1"))
        row = (
            await db.execute(
                select(
                    func.count(CatalogTrackIndex.id),
                    func.coalesce(
                        func.sum(case((CatalogTrackIndex.session_eligible.is_(True), 1), else_=0)), 0
                    ),
                    func.max(CatalogTrackIndex.indexed_at),
                )
            )
        ).one()
    except Exception:
        log.exception("Health check failed")
        return JSONResponse(
            {"status": "degraded", "db": "error", "catalog_tracks": 0,
             "session_eligible": 0, "generated_at": None, "version": "0.12.0"},
            status_code=503,
        )
    total, eligible, indexed_at = row
    return JSONResponse(
        {
            "status": "ok",
            "db": "ok",
            "catalog_tracks": int(total),
            "session_eligible": int(eligible),
            "generated_at": indexed_at.isoformat() if indexed_at else None,
            "version": "0.12.0",
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 8000)),
        reload=os.environ.get("RELOAD", "true").lower() == "true",
        log_level="info",
    )
