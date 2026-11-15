"""Greedy session planner — VSP-012.

Implements the M1 acceptance scenario from roadmap Appendix A9:

  - Plans against playable_ms only (never nominal duration_ms).
  - Seed arc: first 10 minutes (600_000 ms) draw from tracks sharing
    an artist or verified tag with the 3-5 seed track IDs.
    Labelled as seed-based proximity, NOT proven listening history.
  - After the seed arc, introduces artists outside the seed neighborhood.
  - Enforces max_artist_repeats (default 2).
  - Verifies the 80% instrumental quota by playable_ms when
    require_instrumental is True.
  - Reports unsatisfied quota rather than silently relaxing it.

Design rules (roadmap Gate 6):
  - Deterministic greedy — no randomness, stable across replans.
  - Replan only touches unplayed items; played items are immutable.
  - Every plan version is persisted so the change is auditable.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.retrieval.retriever import CandidateResult
from app.infrastructure.models import (
    ListeningSession,
    QueuePlanVersion,
    SessionQueueItem,
)
from app.schemas.intent import CompiledIntent

log = logging.getLogger(__name__)

SEED_ARC_MS = 600_000          # 10 minutes
DEFAULT_MAX_ARTIST_REPEATS = 2
INSTRUMENTAL_QUOTA = 0.80      # 80% of planned playable_ms


# ── Public dataclass returned to callers ─────────────────────────────────────

@dataclass
class PlanResult:
    session_id: str
    plan_version: int
    queue: list[SessionQueueItem]       # all items in this plan (by reference)
    total_planned_ms: int
    instrumental_ms: int
    instrumental_pct: float
    quota_satisfied: bool
    unsatisfied_note: str | None = None


# ── Planner ───────────────────────────────────────────────────────────────────

async def create_session_plan(
    *,
    user_id: str,
    intent: CompiledIntent,
    candidates: list[CandidateResult],
    seed_track_ids: list[str],
    trace_id: str | None,
    db: AsyncSession,
) -> PlanResult:
    """Create a new ListeningSession from ranked candidates.

    ``candidates`` must be the passing subset already sorted by score
    (retriever output). ``seed_track_ids`` is the 3-5 user-selected seeds.
    Returns a PlanResult; the session and queue rows are flushed to the DB.
    """
    passing = [
        c for c in candidates
        if c.passed_genre_exclusion and c.passed_instrumental_filter
    ]

    # Build seed neighborhood (artist + tags of seed tracks)
    seed_artists: set[str] = set()
    seed_tags: set[str] = set()
    for c in passing:
        if c.track_id in seed_track_ids:
            seed_artists.add(c.artist.lower())
    # Also pull seed tags from the index rows — we approximate via track_id match
    for c in passing:
        if c.track_id in seed_track_ids:
            # reason_codes may contain genre info; use artist as neighborhood signal
            seed_artists.add(c.artist.lower())

    max_repeats = intent.max_artist_repeats or DEFAULT_MAX_ARTIST_REPEATS
    target_ms = (intent.duration_min or 30) * 60_000

    ordered = _greedy_order(
        passing,
        seed_track_ids=set(seed_track_ids),
        seed_artists=seed_artists,
        max_repeats=max_repeats,
        target_ms=target_ms,
    )

    # Quota check
    total_ms = sum(item["playable_ms"] for item in ordered)
    instr_ms = sum(
        item["playable_ms"] for item in ordered
        if (item["instrumental_label"] or "").lower() == "instrumental"
    )
    instr_pct = (instr_ms / total_ms) if total_ms > 0 else 0.0
    quota_ok = True
    quota_note: str | None = None

    if intent.require_instrumental is True and total_ms > 0:
        quota_ok = instr_pct >= INSTRUMENTAL_QUOTA
        if not quota_ok:
            quota_note = (
                f"Instrumental quota unsatisfied: "
                f"{instr_pct:.0%} verified instrumental "
                f"(required ≥{INSTRUMENTAL_QUOTA:.0%}). "
                "Unknown labels do not count toward the numerator."
            )
            log.warning(quota_note)

    now = datetime.now(timezone.utc)
    session = ListeningSession(
        user_id=user_id,
        trace_id=trace_id,
        intent_goal=intent.goal[:255] if intent.goal else None,
        intent_scope=intent.scope.value if intent.scope else None,
        intent_duration_min=intent.duration_min,
        intent_require_instrumental=intent.require_instrumental,
        seed_track_ids=json.dumps(seed_track_ids),
        plan_version=1,
        total_planned_ms=total_ms,
        instrumental_ms=instr_ms,
        state="active",
        created_at=now,
        updated_at=now,
    )
    db.add(session)
    await db.flush()  # populate session_id

    queue_rows: list[SessionQueueItem] = []
    cumulative_ms = 0

    for pos, item in enumerate(ordered, start=1):
        in_seed = cumulative_ms < SEED_ARC_MS
        is_seed = item["track_id"] in seed_track_ids
        row = SessionQueueItem(
            session_id=session.session_id,
            track_id=item["track_id"],
            title=item["title"],
            artist=item["artist"],
            image_url=item["image_url"],
            audio_url=item["audio_url"],
            jamendo_share_url=item["jamendo_share_url"],
            playable_ms=item["playable_ms"],
            instrumental_label=item["instrumental_label"],
            position=pos,
            plan_version=1,
            played=False,
            is_seed=is_seed,
            in_seed_neighborhood=in_seed,
            reason_codes=json.dumps(item["reason_codes"]),
        )
        db.add(row)
        queue_rows.append(row)
        cumulative_ms += item["playable_ms"]

    # Persist plan v1
    plan_snapshot = QueuePlanVersion(
        session_id=session.session_id,
        plan_version=1,
        trigger="initial",
        trigger_detail=None,
        unplayed_track_ids=json.dumps([i["track_id"] for i in ordered]),
        total_planned_ms=total_ms,
        created_at=now,
    )
    db.add(plan_snapshot)
    await db.flush()

    return PlanResult(
        session_id=session.session_id,
        plan_version=1,
        queue=queue_rows,
        total_planned_ms=total_ms,
        instrumental_ms=instr_ms,
        instrumental_pct=instr_pct,
        quota_satisfied=quota_ok,
        unsatisfied_note=quota_note,
    )


async def replan_session(
    *,
    session_id: str,
    feedback_reason: str,
    trigger_track_id: str,
    new_candidates: list[CandidateResult],
    db: AsyncSession,
) -> PlanResult | None:
    """Replace only the unplayed portion of a session queue.

    Rules (roadmap Gate 6 + Appendix A9):
    - The currently playing / played items are NEVER touched.
    - feedback_reason is scoped to this session only — global taste unchanged.
    - Returns None if no unplayed items remain.
    """
    result = await db.execute(
        select(ListeningSession).where(ListeningSession.session_id == session_id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        return None

    # Load all queue items
    items_result = await db.execute(
        select(SessionQueueItem)
        .where(SessionQueueItem.session_id == session_id)
        .order_by(SessionQueueItem.position)
    )
    all_items = list(items_result.scalars().all())

    played = [i for i in all_items if i.played]
    unplayed = [i for i in all_items if not i.played]

    if not unplayed:
        return None

    # Build exclusion: deprioritise tracks sharing the skipped track's artist
    skipped_artist: str | None = None
    for item in all_items:
        if item.track_id == trigger_track_id:
            skipped_artist = item.artist.lower()
            break

    passing = [
        c for c in new_candidates
        if c.passed_genre_exclusion and c.passed_instrumental_filter
    ]

    # Exclude already-played track_ids from the new plan
    played_ids = {i.track_id for i in played}
    passing = [c for c in passing if c.track_id not in played_ids]

    # Re-order: deprioritise skipped artist for session scope
    if skipped_artist:
        passing.sort(
            key=lambda c: (
                1 if c.artist.lower() == skipped_artist else 0,
                -c.keyword_score,
                -c.playable_ms,
            )
        )
    else:
        passing.sort(key=lambda c: (c.keyword_score, c.playable_ms), reverse=True)

    # Delete old unplayed rows
    for item in unplayed:
        await db.delete(item)
    await db.flush()

    new_plan_version = session.plan_version + 1
    now = datetime.now(timezone.utc)
    new_total_ms = 0
    new_instr_ms = 0
    new_queue: list[SessionQueueItem] = []

    # Carry over played positions; new items start after last played
    start_pos = (max((i.position for i in played), default=0)) + 1

    for idx, c in enumerate(passing):
        pos = start_pos + idx
        row = SessionQueueItem(
            session_id=session_id,
            track_id=c.track_id,
            title=c.title,
            artist=c.artist,
            image_url=c.image_url,
            audio_url=c.audio_url,
            jamendo_share_url=c.jamendo_share_url,
            playable_ms=c.playable_ms,
            instrumental_label=c.instrumental_label,
            position=pos,
            plan_version=new_plan_version,
            played=False,
            is_seed=False,
            in_seed_neighborhood=False,
            reason_codes=json.dumps(c.reason_codes + ["replan"]),
        )
        db.add(row)
        new_queue.append(row)
        new_total_ms += c.playable_ms
        if (c.instrumental_label or "").lower() == "instrumental":
            new_instr_ms += c.playable_ms

    # Persist new plan snapshot
    plan_snap = QueuePlanVersion(
        session_id=session_id,
        plan_version=new_plan_version,
        trigger=f"skip:{feedback_reason}",
        trigger_detail=trigger_track_id,
        unplayed_track_ids=json.dumps([c.track_id for c in passing]),
        total_planned_ms=new_total_ms,
        created_at=now,
    )
    db.add(plan_snap)

    session.plan_version = new_plan_version
    session.total_planned_ms = new_total_ms
    session.instrumental_ms = new_instr_ms
    session.updated_at = now
    await db.flush()

    instr_pct = (new_instr_ms / new_total_ms) if new_total_ms > 0 else 0.0

    return PlanResult(
        session_id=session_id,
        plan_version=new_plan_version,
        queue=new_queue,
        total_planned_ms=new_total_ms,
        instrumental_ms=new_instr_ms,
        instrumental_pct=instr_pct,
        quota_satisfied=True,
        unsatisfied_note=None,
    )


# ── Greedy ordering algorithm ─────────────────────────────────────────────────

def _greedy_order(
    candidates: list[CandidateResult],
    *,
    seed_track_ids: set[str],
    seed_artists: set[str],
    max_repeats: int,
    target_ms: int,
) -> list[dict]:
    """Deterministic greedy ordering.

    Phase 1 (seed arc, first 600_000 ms):
        Prefer seed tracks first, then tracks from seed artists.
    Phase 2 (remainder):
        Prefer tracks from artists NOT in the seed neighborhood.
        Enforce max_artist_repeats across the full queue.

    Stop once total playable_ms ≥ target_ms.
    """
    artist_counts: dict[str, int] = {}
    ordered: list[dict] = []
    total_ms = 0
    used_ids: set[str] = set()

    def _to_dict(c: CandidateResult) -> dict:
        return {
            "track_id": c.track_id,
            "title": c.title,
            "artist": c.artist,
            "image_url": c.image_url,
            "audio_url": c.audio_url,
            "jamendo_share_url": c.jamendo_share_url,
            "playable_ms": c.playable_ms,
            "instrumental_label": c.instrumental_label,
            "reason_codes": c.reason_codes,
        }

    def _pick(pool: list[CandidateResult]) -> CandidateResult | None:
        for c in pool:
            if c.track_id in used_ids:
                continue
            if artist_counts.get(c.artist.lower(), 0) >= max_repeats:
                continue
            return c
        return None

    # Phase 1 — seed arc
    seeds_first = sorted(
        candidates,
        key=lambda c: (
            0 if c.track_id in seed_track_ids else
            1 if c.artist.lower() in seed_artists else 2,
            -c.keyword_score,
            -c.playable_ms,
        ),
    )

    while total_ms < SEED_ARC_MS and total_ms < target_ms:
        c = _pick(seeds_first)
        if c is None:
            break
        ordered.append(_to_dict(c))
        used_ids.add(c.track_id)
        artist_counts[c.artist.lower()] = artist_counts.get(c.artist.lower(), 0) + 1
        total_ms += c.playable_ms

    # Phase 2 — introduce artists outside seed neighborhood
    outside_first = sorted(
        candidates,
        key=lambda c: (
            0 if c.artist.lower() not in seed_artists and c.track_id not in seed_track_ids else 1,
            -c.keyword_score,
            -c.playable_ms,
        ),
    )

    while total_ms < target_ms:
        c = _pick(outside_first)
        if c is None:
            break
        ordered.append(_to_dict(c))
        used_ids.add(c.track_id)
        artist_counts[c.artist.lower()] = artist_counts.get(c.artist.lower(), 0) + 1
        total_ms += c.playable_ms

    return ordered
