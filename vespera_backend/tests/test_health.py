from datetime import datetime, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.infrastructure.database import Base, get_db
from app.infrastructure.models import CatalogTrackIndex

_engine = create_async_engine("sqlite+aiosqlite:///:memory:", connect_args={"check_same_thread": False})
_Session = async_sessionmaker(_engine, expire_on_commit=False, autoflush=False)


@pytest_asyncio.fixture
async def session():
    async with _engine.begin() as conn:
        import app.infrastructure.models  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
    async with _Session() as s:
        yield s
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client(session):
    from main import app

    async def _override():
        yield session

    app.dependency_overrides[get_db] = _override
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


def _row(track_id: str, eligible: bool) -> CatalogTrackIndex:
    return CatalogTrackIndex(
        track_id=track_id, title="t", artist="a", playable_ms=1000 if eligible else 0,
        session_eligible=eligible, tags_text="", search_text="t a", catalog_version="v1",
        indexed_at=datetime(2026, 11, 15, tzinfo=timezone.utc),
    )


@pytest.mark.asyncio
async def test_health_ok_with_empty_catalog(client):
    response = await client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok" and body["catalog_tracks"] == 0 and body["generated_at"] is None


@pytest.mark.asyncio
async def test_health_reports_counts_once_catalog_is_loaded(client, session):
    session.add_all([_row("1", True), _row("2", True), _row("3", False)])
    await session.commit()
    body = (await client.get("/health")).json()
    assert body["status"] == "ok" and body["db"] == "ok"
    assert body["catalog_tracks"] == 3 and body["session_eligible"] == 2
    assert body["generated_at"].startswith("2026-11-15")


@pytest.mark.asyncio
async def test_health_returns_503_when_db_fails(client):
    from main import app

    class _BrokenSession:
        async def execute(self, *args, **kwargs):
            raise RuntimeError("db down")

    async def _broken():
        yield _BrokenSession()

    previous = app.dependency_overrides[get_db]
    app.dependency_overrides[get_db] = _broken
    try:
        response = await client.get("/health")
    finally:
        app.dependency_overrides[get_db] = previous
    assert response.status_code == 503
    assert response.json()["status"] == "degraded"
