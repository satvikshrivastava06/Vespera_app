"""Session endpoints — VSP-012.

POST /api/v1/sessions            — compile intent, run retrieval, create planned session
GET  /api/v1/sessions/{id}       — read session state and current queue
POST /api/v1/sessions/{id}/feedback — record skip reason, replan unplayed queue
"""

from __future__ import annotations

import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.events import _require_device
from app.domain.intent.compiler import IntentCompiler
from app.domain.planner.greedy import create_session_plan, replan_session
from app.domain.retrieval.indexer import index_catalog
from app.domain.retrieval.retriever import retrieve
from app.domain.retrieval.tracer import persist_trace
from app.infrastructure.database import get_db
from app.infrastructure.models import (
    DeviceToken, ListeningSession, QueuePlanVersion, SessionQueueItem,
)
from app.schemas.session import (
    CreateSessionRequest, FeedbackResponse, QueueItemResponse,
    SessionFeedbackRequest, SessionResponse,
)

router = APIRouter(tags=["sessions"])

_compiler = IntentCompiler()


def _queue_item_to_response(item: SessionQueueItem) -> QueueItemResponse:
    try:
        rc = json.loads(item.reason_codes or "[]")
    except (json.JSONDecodeError, TypeError):
        rc = []
    return QueueItemResponse(
        track_id=item.track_id,
        title=item.title,
        artist=item.artist,
        image_url=item.image_url,
        audio_url=item.audio_url,
        jamendo_share_url=item.jamendo_share_url,
        playable_ms=item.playable_ms,
        position=item.position,
        is_seed=item.is_seed,
        in_seed_neighborhood=item.in_seed_neighborhood,
        reason_codes=rc,
    )


# ── POST /api/v1/sessions ─────────────────────────────────────────────────────

@router.post("/sessions", response_model=SessionResponse, status_code=201)
async def create_session(
    body: CreateSessionRequest,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> SessionResponse:
    """Compile intent, retrieve candidates, build a greedy session plan."""
    # Ensure catalog index is current
    await index_catalog(db)

    intent = _compiler.compile(body.text)
    trace_id = str(uuid.uuid4())
    request_id = body.request_id or str(uuid.uuid4())

    candidates = await retrieve(intent, db, limit=50)

    if candidates:
        await persist_trace(
            trace_id=trace_id,
            request_id=request_id,
            user_id=device.user_id,
            intent=intent,
            candidates=candidates,
            catalog_version=None,
            db=db,
        )

    plan = await create_session_plan(
        user_id=device.user_id,
        intent=intent,
        candidates=candidates,
        seed_track_ids=body.seed_track_ids[:5],
        trace_id=trace_id,
        db=db,
    )

    return SessionResponse(
        session_id=plan.session_id,
        plan_version=plan.plan_version,
        intent_goal=intent.goal,
        intent_scope=intent.scope.value,
        intent_duration_min=intent.duration_min,
        total_planned_ms=plan.total_planned_ms,
        instrumental_ms=plan.instrumental_ms,
        instrumental_pct=round(plan.instrumental_pct, 3),
        quota_satisfied=plan.quota_satisfied,
        unsatisfied_note=plan.unsatisfied_note,
        state="active",
        queue=[_queue_item_to_response(i) for i in plan.queue],
        trace_id=trace_id,
    )


# ── GET /api/v1/sessions/{id} ─────────────────────────────────────────────────

@router.get("/sessions/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: str,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> SessionResponse:
    result = await db.execute(
        select(ListeningSession).where(ListeningSession.session_id == session_id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    if session.user_id != device.user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    items_result = await db.execute(
        select(SessionQueueItem)
        .where(SessionQueueItem.session_id == session_id)
        .order_by(SessionQueueItem.position)
    )
    items = list(items_result.scalars().all())
    total_ms = sum(i.playable_ms for i in items if not i.played)
    instr_ms = sum(
        i.playable_ms for i in items
        if not i.played and (i.instrumental_label or "").lower() == "instrumental"
    )
    instr_pct = (instr_ms / total_ms) if total_ms > 0 else 0.0

    return SessionResponse(
        session_id=session.session_id,
        plan_version=session.plan_version,
        intent_goal=session.intent_goal,
        intent_scope=session.intent_scope,
        intent_duration_min=session.intent_duration_min,
        total_planned_ms=total_ms,
        instrumental_ms=instr_ms,
        instrumental_pct=round(instr_pct, 3),
        quota_satisfied=True,
        state=session.state,
        queue=[_queue_item_to_response(i) for i in items],
        trace_id=session.trace_id,
    )


# ── POST /api/v1/sessions/{id}/feedback ──────────────────────────────────────

@router.post("/sessions/{session_id}/feedback", response_model=FeedbackResponse)
async def session_feedback(
    session_id: str,
    body: SessionFeedbackRequest,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> FeedbackResponse:
    """Record a skip reason and replan only the unplayed queue.

    - The currently playing / played items are NEVER modified.
    - The skip reason is scoped to this session — global taste is unchanged.
    - feedback_reason='not_now' must not become a permanent dislike.
    """
    result = await db.execute(
        select(ListeningSession).where(ListeningSession.session_id == session_id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found.")
    if session.user_id != device.user_id:
        raise HTTPException(status_code=403, detail="Access denied.")
    if session.state != "active":
        raise HTTPException(status_code=409, detail=f"Session is {session.state}.")

    # Mark the skipped track as played
    skip_result = await db.execute(
        select(SessionQueueItem).where(
            SessionQueueItem.session_id == session_id,
            SessionQueueItem.track_id == body.track_id,
            SessionQueueItem.played == False,  # noqa: E712
        )
    )
    skipped_item = skip_result.scalar_one_or_none()
    if skipped_item:
        skipped_item.played = True
        await db.flush()

    # Retrieve fresh candidates with the same intent (session-scoped adjustment)
    intent_result = await db.execute(
        select(ListeningSession.intent_goal, ListeningSession.intent_scope)
        .where(ListeningSession.session_id == session_id)
    )
    row = intent_result.one_or_none()
    goal_text = (row[0] if row else None) or "music"

    intent = _compiler.compile(goal_text)
    new_candidates = await retrieve(intent, db, limit=50)

    plan = await replan_session(
        session_id=session_id,
        feedback_reason=body.feedback_reason,
        trigger_track_id=body.track_id,
        new_candidates=new_candidates,
        db=db,
    )

    if plan is None:
        return FeedbackResponse(
            session_id=session_id,
            plan_version=session.plan_version,
            replanned=False,
            message="No unplayed tracks remain in this session.",
        )

    return FeedbackResponse(
        session_id=session_id,
        plan_version=plan.plan_version,
        replanned=True,
        new_queue=[_queue_item_to_response(i) for i in plan.queue],
        message=(
            f"Queue replanned (v{plan.plan_version}) after skip: {body.feedback_reason}. "
            "Session scope only — global taste unchanged."
        ),
    )
