"""VSP-011 tests: catalog indexer, DB retriever, trace persistence, trace API.

All tests use an in-memory SQLite database — no Postgres required.
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy import select

from app.infrastructure.database import Base, get_db
from app.infrastructure.models import (
    CatalogTrackIndex, RecommendationTrace, TraceItem,
)

# ── Shared test DB fixture ────────────────────────────────────────────────────

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
_engine = create_async_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
_Session = async_sessionmaker(_engine, expire_on_commit=False, autoflush=False)


@pytest_asyncio.fixture(scope="function")
async def db():
    async with _engine.begin() as conn:
        import app.infrastructure.models  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
    async with _Session() as session:
        yield session
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db):
    from main import app

    async def _override():
        yield db

    app.dependency_overrides[get_db] = _override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def token(client):
    r = await client.post("/api/v1/auth/anonymous")
    return r.json()["token"]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_index_row(
    track_id: str = "j:1",
    title: str = "Deep Focus Piano",
    artist: str = "Test Artist",
    tags: list[str] | None = None,
    instrumental: bool = True,
    session_eligible: bool = True,
    playable_ms: int = 180_000,
) -> CatalogTrackIndex:
    tags = tags or ["piano", "focus", "instrumental"]
    search_text = " ".join([title, artist] + tags).lower()
    return CatalogTrackIndex(
        track_id=track_id,
        title=title,
        artist=artist,
        image_url=None,
        audio_url="https://cdn.example.com/stream.mp3" if session_eligible else None,
        jamendo_share_url="https://www.jamendo.com/track/1",
        playable_ms=playable_ms if session_eligible else 0,
        session_eligible=session_eligible,
        instrumental_label="instrumental" if instrumental else "vocal",
        license="https://creativecommons.org/licenses/by-nc-sa/3.0/",
        tags_text=" ".join(tags),
        search_text=search_text,
        catalog_version="test-v1",
        indexed_at=datetime.now(timezone.utc),
    )


def _make_intent(
    keywords: list[str] | None = None,
    preferred_genres: list[str] | None = None,
    excluded_genres: list[str] | None = None,
    require_instrumental: bool | None = None,
):
    from app.schemas.intent import CompiledIntent
    return CompiledIntent(
        goal="Test",
        search_keywords=keywords or [],
        preferred_genres=preferred_genres or [],
        excluded_genres=excluded_genres or [],
        require_instrumental=require_instrumental,
    )


# ── 1. Catalog indexer ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_indexer_inserts_rows(db):
    """index_catalog should populate catalog_track_index from the JSON file."""
    from unittest.mock import patch
    from app.domain.retrieval.indexer import index_catalog
    from app.schemas.catalog import CatalogFile, CatalogTrack
    from app.schemas.track import DataRightsRecord, PlaybackMode, ProviderTrack

    now = datetime.now(timezone.utc)
    track = CatalogTrack(
        id="j:test:1",
        title="Calm Piano",
        artist="Artist A",
        tags=["instrumental", "piano"],
        instrumental_label="instrumental",
        duration_ms=200_000,
        provider_track=ProviderTrack(
            provider="jamendo", provider_track_id="1",
            playback_mode=PlaybackMode.FULL_LICENSED,
            audio_url="https://example.com/s.mp3",
            playable_ms=200_000, session_eligible=True,
            rights_record_id=1,
            license="https://creativecommons.org/licenses/by-nc-sa/3.0/",
            verified_at=now,
        ),
        rights=DataRightsRecord(
            source="jamendo", policy_version="m1",
            session_eligible=True, terms_confirmed_on=now, decided_at=now,
        ),
    )
    fake_catalog = CatalogFile(policy_version="m1", tracks=[track])

    with patch("app.domain.retrieval.indexer.load_catalog", return_value=fake_catalog):
        count = await index_catalog(db)

    assert count == 1
    result = await db.execute(select(CatalogTrackIndex))
    rows = result.scalars().all()
    assert len(rows) == 1
    assert rows[0].track_id == "j:test:1"
    assert "piano" in rows[0].search_text
    assert rows[0].session_eligible is True


@pytest.mark.asyncio
async def test_indexer_skips_on_same_version(db):
    """Re-indexing with the same catalog version must be a no-op."""
    from unittest.mock import patch
    from app.domain.retrieval.indexer import index_catalog
    from app.schemas.catalog import CatalogFile, CatalogTrack
    from app.schemas.track import DataRightsRecord, PlaybackMode, ProviderTrack

    now = datetime.now(timezone.utc)

    def _make_track(tid):
        return CatalogTrack(
            id=tid, title=f"Track {tid}", artist="A", tags=[],
            duration_ms=100_000,
            provider_track=ProviderTrack(
                provider="jamendo", provider_track_id=tid,
                playback_mode=PlaybackMode.FULL_LICENSED,
                audio_url="https://x.com/s.mp3",
                playable_ms=100_000, session_eligible=True,
                rights_record_id=1,
                license="https://creativecommons.org/licenses/by/4.0/",
                verified_at=now,
            ),
            rights=DataRightsRecord(
                source="jamendo", policy_version="m1",
                session_eligible=True, terms_confirmed_on=now, decided_at=now,
            ),
        )

    fake = CatalogFile(policy_version="m1", tracks=[_make_track("t1")])
    with patch("app.domain.retrieval.indexer.load_catalog", return_value=fake):
        c1 = await index_catalog(db)
        c2 = await index_catalog(db)  # same catalog → skip

    assert c1 == 1
    assert c2 == 0  # skipped


# ── 2. Retriever ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_retriever_returns_keyword_matches(db):
    db.add(_make_index_row("j:1", title="Calm Piano", tags=["piano", "focus", "instrumental"]))
    db.add(_make_index_row("j:2", title="Rock Power", tags=["rock", "electric", "guitar"], instrumental=False))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    intent = _make_intent(keywords=["piano", "focus"])
    results = await retrieve(intent, db)

    passing = [r for r in results if r.passed_genre_exclusion and r.passed_instrumental_filter]
    assert any(r.track_id == "j:1" for r in passing)
    piano = next(r for r in passing if r.track_id == "j:1")
    assert piano.keyword_score >= 2
    assert "piano" in piano.matched_keywords or "focus" in piano.matched_keywords


@pytest.mark.asyncio
async def test_retriever_excludes_genre(db):
    db.add(_make_index_row("j:1", title="Hip Hop Beat", tags=["hip hop", "rap"]))
    db.add(_make_index_row("j:2", title="Calm Flute", tags=["flute", "calm"]))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    intent = _make_intent(keywords=["calm", "hip hop"], excluded_genres=["hip hop"])
    results = await retrieve(intent, db)

    excluded = [r for r in results if not r.passed_genre_exclusion]
    passing = [r for r in results if r.passed_genre_exclusion and r.passed_instrumental_filter]
    assert any(r.track_id == "j:1" for r in excluded)
    assert not any(r.track_id == "j:1" for r in passing)


@pytest.mark.asyncio
async def test_retriever_instrumental_filter(db):
    db.add(_make_index_row("j:1", title="Vocal Song", tags=["pop"], instrumental=False))
    db.add(_make_index_row("j:2", title="Pure Piano", tags=["piano", "instrumental"], instrumental=True))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    intent = _make_intent(keywords=["piano"], require_instrumental=True)
    results = await retrieve(intent, db)

    passing = [r for r in results if r.passed_genre_exclusion and r.passed_instrumental_filter]
    assert all(r.instrumental_label == "instrumental" for r in passing)
    assert not any(r.track_id == "j:1" for r in passing)


@pytest.mark.asyncio
async def test_retriever_non_eligible_excluded(db):
    """Non-session-eligible tracks must never appear in results."""
    db.add(_make_index_row("j:1", title="Preview Only", session_eligible=False))
    db.add(_make_index_row("j:2", title="Full Stream", session_eligible=True))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    intent = _make_intent(keywords=["preview", "stream", "full"])
    results = await retrieve(intent, db)

    assert not any(r.track_id == "j:1" for r in results)


@pytest.mark.asyncio
async def test_retriever_empty_index_returns_empty(db):
    from app.domain.retrieval.retriever import retrieve
    results = await retrieve(_make_intent(keywords=["jazz"]), db)
    assert results == []


@pytest.mark.asyncio
async def test_retriever_scores_descending(db):
    db.add(_make_index_row("j:1", title="Jazz Piano Focus", tags=["jazz", "piano", "focus"]))
    db.add(_make_index_row("j:2", title="Jazz Only", tags=["jazz"]))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    intent = _make_intent(keywords=["jazz", "piano", "focus"])
    results = await retrieve(intent, db)
    passing = [r for r in results if r.passed_genre_exclusion and r.passed_instrumental_filter]
    # j:1 matches 3 keywords, j:2 matches 1 → j:1 must rank first
    assert passing[0].track_id == "j:1"


# ── 3. Trace persistence ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_trace_persisted_with_items(db):
    db.add(_make_index_row("j:1", title="Focus Beats", tags=["focus", "instrumental"]))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    from app.domain.retrieval.tracer import persist_trace
    intent = _make_intent(keywords=["focus"])
    candidates = await retrieve(intent, db)

    tid = str(uuid.uuid4())
    trace = await persist_trace(
        trace_id=tid,
        request_id=str(uuid.uuid4()),
        user_id="test-user",
        intent=intent,
        candidates=candidates,
        catalog_version="test-v1",
        db=db,
    )
    assert trace.trace_id == tid
    assert trace.candidate_count == len(candidates)
    assert trace.returned_count >= 0
    assert trace.policy_version == "b0-keyword-v1"

    # Verify items persisted
    items_r = await db.execute(select(TraceItem).where(TraceItem.trace_id == tid))
    items = items_r.scalars().all()
    assert len(items) == len(candidates)


@pytest.mark.asyncio
async def test_trace_exclusion_reason_recorded(db):
    db.add(_make_index_row("j:1", title="Hip Hop Flow", tags=["hip hop"]))
    await db.flush()

    from app.domain.retrieval.retriever import retrieve
    from app.domain.retrieval.tracer import persist_trace
    intent = _make_intent(keywords=["hip hop"], excluded_genres=["hip hop"])
    candidates = await retrieve(intent, db)
    tid = str(uuid.uuid4())
    await persist_trace(
        trace_id=tid, request_id=None, user_id="u",
        intent=intent, candidates=candidates, catalog_version=None, db=db,
    )
    items_r = await db.execute(select(TraceItem).where(TraceItem.trace_id == tid))
    items = items_r.scalars().all()
    excluded = [i for i in items if i.final_rank is None]
    assert any(i.exclusion_reason and "excluded_genre" in i.exclusion_reason for i in excluded)


# ── 4. Trace API endpoint ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_trace_api_returns_stored_trace(client, token, db):
    # Seed a track and run a Twilight request to generate a trace
    db.add(_make_index_row("j:api:1", title="Study Piano", tags=["study", "piano", "instrumental"]))
    await db.flush()
    await db.commit()

    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "piano study music"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    trace_id = resp.json()["trace_id"]

    # Fetch the trace
    tr = await client.get(
        f"/api/v1/traces/{trace_id}",
        headers={"X-Device-Token": token},
    )
    assert tr.status_code == 200
    body = tr.json()
    assert body["trace_id"] == trace_id
    assert body["intent_goal"]
    assert isinstance(body["items"], list)


@pytest.mark.asyncio
async def test_trace_api_404_for_unknown(client, token):
    resp = await client.get(
        f"/api/v1/traces/{uuid.uuid4()}",
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_trace_api_requires_auth(client):
    resp = await client.get(f"/api/v1/traces/{uuid.uuid4()}")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_twilight_uses_db_index(client, token, db):
    """End-to-end: Twilight agent should return tracks from the DB index."""
    db.add(_make_index_row(
        "j:e2e:1", title="Ambient Focus",
        tags=["ambient", "instrumental", "focus"],
    ))
    await db.flush()
    await db.commit()

    resp = await client.post(
        "/api/v1/twilight/agent",
        json={"text": "ambient instrumental focus"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ready"
    track_ids = [t["track_id"] for t in body["tracks"]]
    assert "j:e2e:1" in track_ids
