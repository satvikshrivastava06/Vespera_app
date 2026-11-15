"""VSP-007 tests: anonymous token auth and event ingestion.

Uses an in-memory SQLite database (aiosqlite) so no Postgres install is needed.
The DATABASE_URL env var is overridden via monkeypatch before any import that
triggers engine creation would see it — we patch the settings object directly
and rebuild the engine inside each test module's session.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.infrastructure.database import Base, get_db
from app.infrastructure.models import DeviceToken, ListeningEvent

# ---------------------------------------------------------------------------
# In-process SQLite engine / session override
# ---------------------------------------------------------------------------

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

_test_engine = create_async_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
_TestSession = async_sessionmaker(_test_engine, expire_on_commit=False, autoflush=False)


@pytest_asyncio.fixture(scope="function")
async def db():
    """Fresh schema for each test."""
    async with _test_engine.begin() as conn:
        import app.infrastructure.models  # noqa: F401

        await conn.run_sync(Base.metadata.create_all)
    async with _TestSession() as session:
        yield session
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db):
    """HTTPX async client wired to the FastAPI app with the test DB session."""
    # Import app after DB setup so routers are registered.
    from main import app

    async def _override_db():
        yield db

    app.dependency_overrides[get_db] = _override_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Auth: POST /api/v1/auth/anonymous
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_bootstrap_returns_token_and_user_id(client):
    resp = await client.post("/api/v1/auth/anonymous")
    assert resp.status_code == 201
    body = resp.json()
    assert "token" in body
    assert "user_id" in body
    assert len(body["token"]) >= 32
    # user_id should be a valid UUID4
    uuid.UUID(body["user_id"], version=4)


@pytest.mark.asyncio
async def test_bootstrap_stores_hash_not_raw_token(client, db):
    resp = await client.post("/api/v1/auth/anonymous")
    raw_token = resp.json()["token"]
    user_id = resp.json()["user_id"]

    from sqlalchemy import select

    result = await db.execute(select(DeviceToken).where(DeviceToken.user_id == user_id))
    record = result.scalar_one()

    # Raw token must NOT be stored.
    assert record.token_hash != raw_token
    # Hash must be a 64-char hex string (SHA-256).
    assert len(record.token_hash) == 64
    assert all(c in "0123456789abcdef" for c in record.token_hash)


@pytest.mark.asyncio
async def test_two_bootstraps_produce_distinct_tokens(client):
    r1 = await client.post("/api/v1/auth/anonymous")
    r2 = await client.post("/api/v1/auth/anonymous")
    assert r1.json()["token"] != r2.json()["token"]
    assert r1.json()["user_id"] != r2.json()["user_id"]


# ---------------------------------------------------------------------------
# Events: POST /api/v1/events
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_event_rejected_without_token(client):
    resp = await client.post(
        "/api/v1/events",
        json={"event_type": "start"},
    )
    assert resp.status_code == 422  # missing required header


@pytest.mark.asyncio
async def test_event_rejected_with_bad_token(client):
    resp = await client.post(
        "/api/v1/events",
        json={"event_type": "start"},
        headers={"X-Device-Token": "not-a-real-token"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_event_accepted_and_persisted(client, db):
    # Bootstrap a token first.
    auth = await client.post("/api/v1/auth/anonymous")
    token = auth.json()["token"]
    expected_user_id = auth.json()["user_id"]

    event_id = str(uuid.uuid4())
    resp = await client.post(
        "/api/v1/events",
        json={
            "event_id": event_id,
            "event_type": "start",
            "track_id": "jamendo:12345",
            "position_ms": 0,
            "source_surface": "home",
            "occurred_at_utc": datetime.now(timezone.utc).isoformat(),
        },
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["accepted"] is True
    assert body["event_id"] == event_id

    # Verify persisted row.
    from sqlalchemy import select

    result = await db.execute(
        select(ListeningEvent).where(ListeningEvent.event_id == event_id)
    )
    row = result.scalar_one()
    assert row.user_id == expected_user_id  # server-derived, not client-supplied
    assert row.event_type == "start"
    assert row.track_id == "jamendo:12345"


@pytest.mark.asyncio
async def test_event_idempotent_on_duplicate_event_id(client, db):
    auth = await client.post("/api/v1/auth/anonymous")
    token = auth.json()["token"]
    event_id = str(uuid.uuid4())
    payload = {
        "event_id": event_id,
        "event_type": "skip",
        "feedback_reason": "too_energetic",
        "occurred_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    headers = {"X-Device-Token": token}

    r1 = await client.post("/api/v1/events", json=payload, headers=headers)
    r2 = await client.post("/api/v1/events", json=payload, headers=headers)

    assert r1.status_code == 200
    assert r2.status_code == 200
    # Both must return the same row_id — only one row was inserted.
    assert r1.json()["row_id"] == r2.json()["row_id"]

    from sqlalchemy import select, func

    count = await db.execute(
        select(func.count()).where(ListeningEvent.event_id == event_id)
    )
    assert count.scalar_one() == 1


@pytest.mark.asyncio
async def test_client_cannot_override_user_id(client, db):
    """user_id in the JSON body must be ignored; server uses token-derived value."""
    auth = await client.post("/api/v1/auth/anonymous")
    token = auth.json()["token"]
    legitimate_user_id = auth.json()["user_id"]
    attacker_user_id = str(uuid.uuid4())

    event_id = str(uuid.uuid4())
    # Inject a user_id that does not match the token.
    resp = await client.post(
        "/api/v1/events",
        json={
            "event_id": event_id,
            "event_type": "impression",
            # EventIn schema has no user_id field — extra fields are ignored by default.
            "user_id": attacker_user_id,
            "occurred_at_utc": datetime.now(timezone.utc).isoformat(),
        },
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200

    from sqlalchemy import select

    result = await db.execute(
        select(ListeningEvent).where(ListeningEvent.event_id == event_id)
    )
    row = result.scalar_one()
    assert row.user_id == legitimate_user_id
    assert row.user_id != attacker_user_id


@pytest.mark.asyncio
async def test_event_all_allowed_types(client):
    auth = await client.post("/api/v1/auth/anonymous")
    token = auth.json()["token"]
    headers = {"X-Device-Token": token}
    event_types = [
        "session_created", "impression", "start", "heartbeat",
        "pause", "complete", "skip", "save", "replay", "explicit_feedback",
    ]
    for et in event_types:
        resp = await client.post(
            "/api/v1/events",
            json={
                "event_id": str(uuid.uuid4()),
                "event_type": et,
                "occurred_at_utc": datetime.now(timezone.utc).isoformat(),
            },
            headers=headers,
        )
        assert resp.status_code == 200, f"Failed for event_type={et}: {resp.text}"


@pytest.mark.asyncio
async def test_event_rejects_unknown_event_type(client):
    auth = await client.post("/api/v1/auth/anonymous")
    token = auth.json()["token"]
    resp = await client.post(
        "/api/v1/events",
        json={
            "event_id": str(uuid.uuid4()),
            "event_type": "not_a_real_event",
            "occurred_at_utc": datetime.now(timezone.utc).isoformat(),
        },
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_health_still_works(client):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
