"""POST /api/v1/twilight/agent

Single entry point for all Twilight UI interactions.

VSP-009: authenticated path, typed response.
VSP-010: real intent compiler, structured intent.
VSP-011: PostgreSQL FTS/tag retrieval, recommendation_trace persistence.
VSP-012: session planner adds session_id and queue.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.events import _require_device
from app.domain.intent.compiler import IntentCompiler
from app.domain.retrieval.retriever import CandidateResult, retrieve
from app.domain.retrieval.tracer import persist_trace
from app.infrastructure.database import get_db
from app.infrastructure.models import CatalogTrackIndex, DeviceToken
from app.schemas.twilight import (
    TwilightMode,
    TwilightRequest,
    TwilightRequestStatus,
    TwilightResponse,
    TwilightTrackResult,
)

router = APIRouter(tags=["twilight"])

_compiler = IntentCompiler()


def _candidate_to_result(c: CandidateResult) -> TwilightTrackResult:
    return TwilightTrackResult(
        track_id=c.track_id,
        title=c.title,
        artist=c.artist,
        playback_mode="full_licensed" if c.session_eligible else "handoff",
        session_eligible=c.session_eligible,
        playable_ms=c.playable_ms,
        audio_url=c.audio_url,
        jamendo_share_url=c.jamendo_share_url,
        image_url=c.image_url,
        reason_codes=c.reason_codes,
    )


async def _catalog_version(db: AsyncSession) -> str | None:
    result = await db.execute(
        select(CatalogTrackIndex.catalog_version).limit(1)
    )
    return result.scalar_one_or_none()


@router.post("/twilight/agent", response_model=TwilightResponse, status_code=200)
async def twilight_agent(
    body: TwilightRequest,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> TwilightResponse:
    trace_id = str(uuid.uuid4())
    request_id = body.request_id or str(uuid.uuid4())
    text = body.text.strip()

    if len(text) < 2:
        return TwilightResponse(
            request_id=request_id,
            trace_id=trace_id,
            status=TwilightRequestStatus.NEEDS_CLARIFICATION,
            message="Please describe what you'd like to listen to.",
            next_actions=["provide_intent"],
        )

    # ── Compile intent ───────────────────────────────────────────────────────
    intent = _compiler.compile(text)

    if intent.ambiguities and intent.confidence < 0.4:
        return TwilightResponse(
            request_id=request_id,
            trace_id=trace_id,
            status=TwilightRequestStatus.NEEDS_CLARIFICATION,
            message=f"Could you clarify? {' '.join(intent.ambiguities[:2])}",
            intent_goal=intent.goal,
            intent_scope=intent.scope.value,
            unverified_constraints=intent.unverified_constraints,
            next_actions=["provide_clarification"],
        )

    # ── DB retrieval (VSP-011) ───────────────────────────────────────────────
    candidates: list[CandidateResult] = []
    cat_version: str | None = None

    if body.mode in (TwilightMode.CHAT, TwilightMode.SEMANTIC_SEARCH, TwilightMode.SUGGESTION):
        candidates = await retrieve(intent, db, limit=10)
        cat_version = await _catalog_version(db)

    # ── Persist trace ────────────────────────────────────────────────────────
    if candidates:
        await persist_trace(
            trace_id=trace_id,
            request_id=request_id,
            user_id=device.user_id,
            intent=intent,
            candidates=candidates,
            catalog_version=cat_version,
            db=db,
        )

    # Passing candidates only go to the Flutter response
    passing = [
        c for c in candidates
        if c.passed_genre_exclusion and c.passed_instrumental_filter
    ]
    track_results = [_candidate_to_result(c) for c in passing]

    # ── Build response ───────────────────────────────────────────────────────
    common = dict(
        schema_version="1.0",
        request_id=request_id,
        trace_id=trace_id,
        intent_goal=intent.goal,
        intent_scope=intent.scope.value,
        intent_energy=intent.energy.value,
        intent_duration_min=intent.duration_min,
        intent_require_instrumental=intent.require_instrumental,
        intent_excluded_genres=intent.excluded_genres,
        intent_negations=intent.negations_detected,
        unverified_constraints=intent.unverified_constraints,
    )

    if track_results:
        dur_note = f" ({intent.duration_min} min requested)" if intent.duration_min else ""
        return TwilightResponse(
            **common,
            status=TwilightRequestStatus.READY,
            message=f"Found {len(track_results)} rights-cleared track(s) for \"{intent.goal}\"{dur_note}.",
            tracks=track_results,
            next_actions=["play_track", "open_provider"],
        )

    return TwilightResponse(
        **common,
        status=TwilightRequestStatus.PARTIAL,
        message=(
            f"No rights-cleared tracks matched \"{intent.goal}\" in the current catalog. "
            "Seed the catalog with python scripts/seed_jamendo.py and restart the API."
        ),
        next_actions=["seed_catalog"],
    )
