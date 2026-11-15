from __future__ import annotations

"""Twilight agent endpoint tests (VSP-009 / VSP-010 / VSP-011).

Covers: auth guard, request validation, response shape contract,
DB-backed retrieval, non-eligible track exclusion, all modes,
and request_id propagation.
"""

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.infrastructure.database import Base, get_db

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
_test_engine = create_async_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
_TestSession = async_sessionmaker(_test_engine, expire_on_commit=False, autoflush=False)


@pytest_asyncio.fixture(scope="function")
async def db():
    async with _test_engine.begin() as conn:
        import app.infrastructure.models  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
    async with _TestSession() as session:
        yield session
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db):
    from main import app

    async def _override_db():
        yield db

    app.dependency_overrides[get_db] = _override_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture(scope="function")
async def token(client):
    resp = await client.post("/api/v1/auth/anonymous")
    assert resp.status_code == 201
    return resp.json()["token"]


# ---------------------------------------------------------------------------
# Auth guard
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_requires_token(client):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "calm study music"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_twilight_rejects_bad_token(client):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "calm study music"},
        headers={"X-Device-Token": "not-valid"},
    )
    assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Request validation
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_rejects_empty_text(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": " "},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code in (200, 422)
    if resp.status_code == 200:
        assert resp.json()["status"] == "needs_clarification"


@pytest.mark.asyncio
async def test_twilight_rejects_missing_text(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"mode": "chat"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# Response shape
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_response_shape_always_valid(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "jazz piano late night"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "schema_version" in body
    assert "status" in body
    assert "message" in body
    assert "tracks" in body
    assert isinstance(body["tracks"], list)
    assert "request_id" in body
    assert "trace_id" in body
    assert body["schema_version"] == "1.0"


@pytest.mark.asyncio
async def test_twilight_status_is_valid_enum(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "instrumental focus"},
        headers={"X-Device-Token": token},
    )
    assert resp.json()["status"] in ("ready", "needs_clarification", "partial", "error")


# ---------------------------------------------------------------------------
# Catalog search path — DB index (VSP-011)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_empty_catalog_returns_partial(client, token):
    """Empty DB index → partial status, no tracks."""
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "calm instrumental"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "partial"
    assert body["tracks"] == []


@pytest.mark.asyncio
async def test_twilight_catalog_match_returns_ready(client, token, db):
    """One seeded session-eligible row → ready status with that track."""
    from datetime import datetime, timezone
    from app.infrastructure.models import CatalogTrackIndex

    now = datetime.now(timezone.utc)
    db.add(CatalogTrackIndex(
        track_id="jamendo:test:1",
        title="Deep Focus Piano",
        artist="Test Artist",
        image_url=None,
        audio_url="https://example.com/stream.mp3",
        jamendo_share_url="https://www.jamendo.com/track/99999",
        playable_ms=240_000,
        session_eligible=True,
        instrumental_label="instrumental",
        license="https://creativecommons.org/licenses/by-nc-sa/3.0/",
        tags_text="instrumental piano focus",
        search_text="deep focus piano test artist instrumental piano focus",
        catalog_version="test-v1",
        indexed_at=now,
    ))
    await db.flush()
    await db.commit()

    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "piano focus"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ready"
    assert len(body["tracks"]) == 1
    t = body["tracks"][0]
    assert t["track_id"] == "jamendo:test:1"
    assert t["session_eligible"] is True
    assert t["playable_ms"] == 240_000
    assert t["playback_mode"] == "full_licensed"


@pytest.mark.asyncio
async def test_twilight_non_session_tracks_excluded(client, token, db):
    """Non-session-eligible rows must not appear in results."""
    from datetime import datetime, timezone
    from app.infrastructure.models import CatalogTrackIndex

    now = datetime.now(timezone.utc)
    db.add(CatalogTrackIndex(
        track_id="apple:test:1",
        title="Preview Only Song",
        artist="Apple Artist",
        image_url=None,
        audio_url=None,
        jamendo_share_url=None,
        playable_ms=0,
        session_eligible=False,
        instrumental_label=None,
        license=None,
        tags_text="pop",
        search_text="preview only song apple artist pop",
        catalog_version="test-v1",
        indexed_at=now,
    ))
    await db.flush()
    await db.commit()

    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "pop song preview"},
        headers={"X-Device-Token": token},
    )
    assert resp.json()["tracks"] == []


# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_all_modes_accepted(client, token):
    for mode in ("chat", "suggestion", "semantic_search"):
        resp = await client.post(
            "/api/v1/twilight/agent",
            json={"text": "test", "mode": mode},
            headers={"X-Device-Token": token},
        )
        assert resp.status_code == 200, f"mode={mode} failed: {resp.text}"


@pytest.mark.asyncio
async def test_twilight_invalid_mode_rejected(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "test", "mode": "not_a_mode"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# request_id propagation
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_twilight_client_request_id_echoed(client, token):
    my_id = "my-client-request-id-123"
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "instrumental", "request_id": my_id},
        headers={"X-Device-Token": token},
    )
    assert resp.json()["request_id"] == my_id


@pytest.mark.asyncio
async def test_twilight_generates_request_id_if_absent(client, token):
    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "instrumental"},
        headers={"X-Device-Token": token},
    )
    assert resp.json()["request_id"]
    assert resp.json()["trace_id"]
