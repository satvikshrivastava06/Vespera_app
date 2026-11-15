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
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Load .env before any app imports that read settings
load_dotenv()

from app.api.auth import router as auth_router          # noqa: E402
from app.api.catalog import router as catalog_router    # noqa: E402
from app.api.events import router as events_router      # noqa: E402
from app.api.sessions import router as sessions_router  # noqa: E402
from app.api.traces import router as traces_router      # noqa: E402
from app.api.twilight import router as twilight_router  # noqa: E402
from app.infrastructure.database import init_db         # noqa: E402
from app.legacy import home_feed, explore_feed, search  # noqa: E402

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
    application.include_router(home_feed.router, prefix="/api/v1")
    application.include_router(explore_feed.router, prefix="/api/v1")
    application.include_router(search.router, prefix="/api/v1")

    return application


app = create_app()


# ── Health endpoint ───────────────────────────────────────────────────────────

@app.get("/health", tags=["ops"])
async def health() -> dict:
    """Machine-readable health check used by hosting platforms and CI.

    Returns HTTP 200 when the application is ready to serve requests.
    catalog_tracks=0 is not an error — it means the catalog has not been
    seeded yet (run python scripts/seed_jamendo.py).
    """
    from app.infrastructure.database import AsyncSessionLocal
    from app.infrastructure.models import CatalogTrackIndex
    from sqlalchemy import select, func

    db_ok = False
    catalog_tracks = 0
    session_eligible = 0
    generated_at = None

    try:
        async with AsyncSessionLocal() as session:
            # Get counts
            result = await session.execute(select(CatalogTrackIndex))
            rows = result.scalars().all()
            catalog_tracks = len(rows)
            session_eligible = sum(1 for r in rows if r.session_eligible)
            
            # Get latest catalog_generated_at
            if rows:
                max_result = await session.execute(
                    select(func.max(CatalogTrackIndex.catalog_generated_at))
                )
                generated_at = max_result.scalar_one_or_none()
            
            db_ok = True
    except Exception as exc:
        log.error("Health check DB error: %s", exc)

    return {
        "status": "ok" if db_ok else "degraded",
        "db": "ok" if db_ok else "error",
        "catalog_tracks": catalog_tracks,
        "session_eligible": session_eligible,
        "generated_at": generated_at.isoformat() if generated_at else None,
        "version": "0.12.0",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 8000)),
        reload=os.environ.get("RELOAD", "true").lower() == "true",
        log_level="info",
    )
