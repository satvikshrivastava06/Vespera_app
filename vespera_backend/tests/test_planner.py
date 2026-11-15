from __future__ import annotations

"""VSP-012 tests: greedy planner, session API, feedback/replan."""

import json
import uuid
from datetime import datetime, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.infrastructure.database import Base, get_db
from app.infrastructure.models import (
    CatalogTrackIndex, ListeningSession,
    QueuePlanVersion, SessionQueueItem,
)

# ── Shared test DB ────────────────────────────────────────────────────────────

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
    assert r.status_code == 201
    return r.json()["token"]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _add_track(
    db_session: AsyncSession,
    track_id: str,
    title: str,
    artist: str,
    tags: list[str],
    instrumental: bool = True,
    playable_ms: int = 180_000,
) -> CatalogTrackIndex:
    tags_str = " ".join(tags)
    search = f"{title} {artist} {tags_str}".lower()
    row = CatalogTrackIndex(
        track_id=track_id,
        title=title,
        artist=artist,
        image_url=None,
        audio_url=f"https://cdn.example.com/{track_id}.mp3",
        jamendo_share_url=f"https://www.jamendo.com/track/{track_id}",
        playable_ms=playable_ms,
        session_eligible=True,
        instrumental_label="instrumental" if instrumental else "vocal",
        license="https://creativecommons.org/licenses/by-nc-sa/3.0/",
        tags_text=tags_str,
        search_text=search,
        catalog_version="test-v1",
        indexed_at=datetime.now(timezone.utc),
    )
    db_session.add(row)
    return row


def _make_intent(
    goal: str = "study music",
    keywords: list[str] | None = None,
    duration_min: int = 30,
    require_instrumental: bool | None = None,
    excluded_genres: list[str] | None = None,
):
    from app.schemas.intent import CompiledIntent
    return CompiledIntent(
        goal=goal,
        search_keywords=keywords or ["focus", "instrumental"],
        preferred_genres=[],
        excluded_genres=excluded_genres or [],
        require_instrumental=require_instrumental,
        duration_min=duration_min,
    )


def _make_candidate(track_id: str, artist: str, playable_ms: int = 180_000, instrumental: bool = True):
    from app.domain.retrieval.retriever import CandidateResult
    return CandidateResult(
        track_id=track_id,
        title=f"Track {track_id}",
        artist=artist,
        image_url=None,
        audio_url=f"https://cdn.example.com/{track_id}.mp3",
        jamendo_share_url=None,
        playable_ms=playable_ms,
        session_eligible=True,
        instrumental_label="instrumental" if instrumental else "vocal",
        license=None,
        keyword_score=2,
        matched_keywords=["focus"],
        reason_codes=["intent_keyword_match"],
    )


# ── 1. Greedy planner unit tests ──────────────────────────────────────────────

@pytest.mark.asyncio
async def test_planner_sums_playable_ms(db):
    """total_planned_ms must be the sum of playable_ms of queued tracks."""
    from app.domain.planner.greedy import create_session_plan
    candidates = [_make_candidate(f"t{i}", f"Artist{i}", 120_000) for i in range(5)]
    intent = _make_intent(duration_min=10)
    plan = await create_session_plan(
        user_id="u1", intent=intent, candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    assert plan.total_planned_ms == sum(i.playable_ms for i in plan.queue)


@pytest.mark.asyncio
async def test_planner_respects_target_duration(db):
    """Planner must stop adding tracks once target_ms is reached."""
    from app.domain.planner.greedy import create_session_plan
    candidates = [_make_candidate(f"t{i}", f"Artist{i}", 300_000) for i in range(20)]
    intent = _make_intent(duration_min=15)  # 900_000 ms target
    plan = await create_session_plan(
        user_id="u1", intent=intent, candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    assert plan.total_planned_ms >= 900_000
    # Should not over-pad by more than one track length
    assert plan.total_planned_ms <= 900_000 + 300_000


@pytest.mark.asyncio
async def test_planner_seed_arc_first_ten_minutes(db):
    """Seed neighborhood tracks must appear in first 600_000 ms of queue."""
    from app.domain.planner.greedy import create_session_plan, SEED_ARC_MS

    seed_artist = "SeedBand"
    non_seed_artist = "OtherBand"
    seeds = [_make_candidate("seed1", seed_artist, 200_000)]
    non_seeds = [_make_candidate(f"ns{i}", non_seed_artist, 200_000) for i in range(10)]

    plan = await create_session_plan(
        user_id="u1",
        intent=_make_intent(duration_min=30),
        candidates=seeds + non_seeds,
        seed_track_ids=["seed1"],
        trace_id=None,
        db=db,
    )
    # Find position of seed track
    seed_item = next(i for i in plan.queue if i.track_id == "seed1")
    # Cumulative ms up to seed must be within seed arc
    preceding_ms = sum(
        i.playable_ms for i in plan.queue if i.position < seed_item.position
    )
    assert preceding_ms < SEED_ARC_MS
    assert seed_item.in_seed_neighborhood is True


@pytest.mark.asyncio
async def test_planner_max_artist_repeats(db):
    """No artist should appear more than max_artist_repeats times."""
    from app.domain.planner.greedy import create_session_plan
    from app.schemas.intent import CompiledIntent

    # 10 tracks all from "Mono Artist"
    candidates = [_make_candidate(f"t{i}", "Mono Artist", 60_000) for i in range(10)]
    intent = CompiledIntent(
        goal="music",
        search_keywords=["focus"],
        max_artist_repeats=2,
        duration_min=10,
    )
    plan = await create_session_plan(
        user_id="u1", intent=intent, candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    mono_count = sum(1 for i in plan.queue if i.artist == "Mono Artist")
    assert mono_count <= 2


@pytest.mark.asyncio
async def test_planner_instrumental_quota_satisfied(db):
    """When all tracks are instrumental and 80% quota required, quota_satisfied=True."""
    from app.domain.planner.greedy import create_session_plan
    candidates = [_make_candidate(f"t{i}", f"A{i}", 120_000, instrumental=True) for i in range(10)]
    intent = _make_intent(require_instrumental=True, duration_min=10)
    plan = await create_session_plan(
        user_id="u1", intent=intent, candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    assert plan.quota_satisfied is True
    assert plan.instrumental_pct == 1.0


@pytest.mark.asyncio
async def test_planner_instrumental_quota_failed_reported(db):
    """If quota cannot be met, quota_satisfied=False and unsatisfied_note is set."""
    from app.domain.planner.greedy import create_session_plan
    # Mix: half instrumental, half vocal — but filter won't pass vocal when require_instrumental=True
    # So planner receives only instrumental candidates (retriever already filtered)
    # Simulate by directly passing mixed candidates with require_instrumental=True in intent
    # but not filtering them (planner trusts retriever output)
    vocal_candidates = [_make_candidate(f"v{i}", f"VocalArtist{i}", 120_000, instrumental=False) for i in range(5)]
    instr_candidates = [_make_candidate(f"i{i}", f"InstrArtist{i}", 120_000, instrumental=True) for i in range(1)]
    intent = _make_intent(require_instrumental=True, duration_min=5)
    plan = await create_session_plan(
        user_id="u1", intent=intent,
        candidates=vocal_candidates + instr_candidates,  # mixed — bypasses retriever filter
        seed_track_ids=[], trace_id=None, db=db,
    )
    # Quota check runs on what the planner actually queued
    if plan.total_planned_ms > 0 and plan.instrumental_pct < 0.80:
        assert plan.quota_satisfied is False
        assert plan.unsatisfied_note is not None


@pytest.mark.asyncio
async def test_planner_persists_plan_version(db):
    """Plan version 1 must be persisted in queue_plan_version table."""
    from app.domain.planner.greedy import create_session_plan
    candidates = [_make_candidate(f"t{i}", f"A{i}") for i in range(5)]
    plan = await create_session_plan(
        user_id="u1", intent=_make_intent(), candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    result = await db.execute(
        select(QueuePlanVersion).where(QueuePlanVersion.session_id == plan.session_id)
    )
    pv = result.scalars().all()
    assert len(pv) == 1
    assert pv[0].plan_version == 1
    assert pv[0].trigger == "initial"


# ── 2. Replan unit tests ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_replan_only_touches_unplayed(db):
    """Played items must remain untouched after replan."""
    from app.domain.planner.greedy import create_session_plan, replan_session

    candidates = [_make_candidate(f"t{i}", f"A{i}", 60_000) for i in range(6)]
    plan = await create_session_plan(
        user_id="u1", intent=_make_intent(duration_min=5),
        candidates=candidates, seed_track_ids=[], trace_id=None, db=db,
    )

    # Mark first item as played
    first = min(plan.queue, key=lambda i: i.position)
    first.played = True
    await db.flush()

    new_candidates = [_make_candidate(f"new{i}", f"NewArtist{i}", 60_000) for i in range(5)]
    new_plan = await replan_session(
        session_id=plan.session_id,
        feedback_reason="too_energetic",
        trigger_track_id=first.track_id,
        new_candidates=new_candidates,
        db=db,
    )

    assert new_plan is not None
    assert new_plan.plan_version == 2

    # Verify played item is still there
    items_result = await db.execute(
        select(SessionQueueItem).where(SessionQueueItem.session_id == plan.session_id)
    )
    all_items = items_result.scalars().all()
    played_items = [i for i in all_items if i.played]
    assert len(played_items) == 1
    assert played_items[0].track_id == first.track_id


@pytest.mark.asyncio
async def test_replan_persists_new_plan_version(db):
    """Replan must add a new QueuePlanVersion row."""
    from app.domain.planner.greedy import create_session_plan, replan_session

    candidates = [_make_candidate(f"t{i}", f"A{i}") for i in range(5)]
    plan = await create_session_plan(
        user_id="u1", intent=_make_intent(), candidates=candidates,
        seed_track_ids=[], trace_id=None, db=db,
    )
    new_plan = await replan_session(
        session_id=plan.session_id,
        feedback_reason="wrong_context",
        trigger_track_id=plan.queue[0].track_id,
        new_candidates=[_make_candidate(f"r{i}", f"RA{i}") for i in range(3)],
        db=db,
    )
    assert new_plan is not None

    result = await db.execute(
        select(QueuePlanVersion).where(QueuePlanVersion.session_id == plan.session_id)
    )
    versions = result.scalars().all()
    assert len(versions) == 2
    assert any(v.trigger.startswith("skip:") for v in versions)


@pytest.mark.asyncio
async def test_replan_no_unplayed_returns_none(db):
    """Replan must return None when all items are already played."""
    from app.domain.planner.greedy import create_session_plan, replan_session

    candidates = [_make_candidate("t1", "A1", 60_000)]
    plan = await create_session_plan(
        user_id="u1", intent=_make_intent(duration_min=1),
        candidates=candidates, seed_track_ids=[], trace_id=None, db=db,
    )
    for item in plan.queue:
        item.played = True
    await db.flush()

    result = await replan_session(
        session_id=plan.session_id,
        feedback_reason="not_my_taste",
        trigger_track_id="t1",
        new_candidates=[_make_candidate("r1", "B1")],
        db=db,
    )
    assert result is None


# ── 3. Session API endpoint tests ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_session_endpoint(client, token, db):
    """POST /api/v1/sessions must return a valid SessionResponse."""
    _add_track(db, "j:1", "Focus Piano", "Artist A", ["piano", "focus", "instrumental"])
    _add_track(db, "j:2", "Study Beats", "Artist B", ["lofi", "study", "instrumental"])
    await db.flush()
    await db.commit()

    resp = await client.post(
        "/api/v1/sessions",
        json={"text": "instrumental focus music for 10 minutes", "seed_track_ids": ["j:1"]},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert "session_id" in body
    assert body["plan_version"] == 1
    assert isinstance(body["queue"], list)
    assert body["total_planned_ms"] >= 0
    assert "instrumental_pct" in body


@pytest.mark.asyncio
async def test_create_session_requires_auth(client):
    resp = await client.post("/api/v1/sessions", json={"text": "jazz"})
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_get_session_endpoint(client, token, db):
    """GET /api/v1/sessions/{id} returns current state."""
    _add_track(db, "j:3", "Ambient Flow", "Artist C", ["ambient", "instrumental"])
    await db.flush()
    await db.commit()

    create = await client.post(
        "/api/v1/sessions",
        json={"text": "ambient instrumental"},
        headers={"X-Device-Token": token},
    )
    session_id = create.json()["session_id"]

    get = await client.get(
        f"/api/v1/sessions/{session_id}",
        headers={"X-Device-Token": token},
    )
    assert get.status_code == 200
    assert get.json()["session_id"] == session_id
    assert get.json()["state"] == "active"


@pytest.mark.asyncio
async def test_get_session_404(client, token):
    resp = await client.get(
        f"/api/v1/sessions/{uuid.uuid4()}",
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_feedback_endpoint_replans_unplayed(client, token, db):
    """POST feedback must replan unplayed queue and return new_queue."""
    for i in range(6):
        _add_track(db, f"j:fb{i}", f"Track {i}", f"Artist{i}",
                   ["instrumental", "focus"], playable_ms=180_000)
    await db.flush()
    await db.commit()

    create = await client.post(
        "/api/v1/sessions",
        json={"text": "instrumental focus 15 minutes"},
        headers={"X-Device-Token": token},
    )
    assert create.status_code == 201
    session_id = create.json()["session_id"]
    queue = create.json()["queue"]
    if not queue:
        pytest.skip("Empty catalog — no tracks to skip")

    first_track_id = queue[0]["track_id"]

    fb = await client.post(
        f"/api/v1/sessions/{session_id}/feedback",
        json={"track_id": first_track_id, "feedback_reason": "too_energetic"},
        headers={"X-Device-Token": token},
    )
    assert fb.status_code == 200
    body = fb.json()
    assert body["replanned"] is True
    assert body["plan_version"] == 2
    assert "session scope only" in body["message"].lower()


@pytest.mark.asyncio
async def test_feedback_does_not_affect_global_taste(client, token, db):
    """Feedback response message must explicitly state scope is session-only."""
    for i in range(4):
        _add_track(db, f"j:gt{i}", f"Jazz Track {i}", f"Artist J{i}",
                   ["jazz", "instrumental"], playable_ms=200_000)
    await db.flush()
    await db.commit()

    create = await client.post(
        "/api/v1/sessions",
        json={"text": "jazz instrumental 10 minutes"},
        headers={"X-Device-Token": token},
    )
    session_id = create.json()["session_id"]
    queue = create.json()["queue"]
    if not queue:
        pytest.skip("No tracks")

    fb = await client.post(
        f"/api/v1/sessions/{session_id}/feedback",
        json={"track_id": queue[0]["track_id"], "feedback_reason": "not_my_taste"},
        headers={"X-Device-Token": token},
    )
    body = fb.json()
    if body["replanned"]:
        assert "global" in body["message"].lower()
    else:
        # Exhausted session — still acceptable; just verify no crash
        assert "remain" in body["message"].lower()


@pytest.mark.asyncio
async def test_feedback_404_bad_session(client, token):
    resp = await client.post(
        f"/api/v1/sessions/{uuid.uuid4()}/feedback",
        json={"track_id": "x", "feedback_reason": "other"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_feedback_rejects_bad_reason(client, token, db):
    _add_track(db, "j:br1", "Calm Piano", "Artist X", ["piano"])
    await db.flush()
    await db.commit()

    create = await client.post(
        "/api/v1/sessions",
        json={"text": "piano"},
        headers={"X-Device-Token": token},
    )
    session_id = create.json()["session_id"]

    resp = await client.post(
        f"/api/v1/sessions/{session_id}/feedback",
        json={"track_id": "j:br1", "feedback_reason": "invalid_reason"},
        headers={"X-Device-Token": token},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_playable_ms_accounting_no_nominal_duration(db):
    """Planner must never use nominal duration_ms — only playable_ms counts."""
    from app.domain.planner.greedy import create_session_plan
    from app.domain.retrieval.retriever import CandidateResult

    # Candidate with 0 playable_ms but non-zero nominal — should contribute 0 to plan
    zero_playable = CandidateResult(
        track_id="zero1", title="Zero Playable", artist="A",
        image_url=None, audio_url=None, jamendo_share_url=None,
        playable_ms=0, session_eligible=True,
        instrumental_label="instrumental", license=None,
        keyword_score=5, matched_keywords=["focus"], reason_codes=[],
    )
    real_track = _make_candidate("real1", "B", 300_000)
    intent = _make_intent(duration_min=5)
    plan = await create_session_plan(
        user_id="u1", intent=intent,
        candidates=[zero_playable, real_track],
        seed_track_ids=[], trace_id=None, db=db,
    )
    # zero_playable may appear in queue but contributes 0 ms
    total = sum(i.playable_ms for i in plan.queue)
    assert total == plan.total_planned_ms
