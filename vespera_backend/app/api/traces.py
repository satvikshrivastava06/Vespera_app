"""GET /api/v1/traces/{trace_id}

Returns a stored recommendation trace with all candidate items and their
filter/score/rank/reason evidence.  Explanations must be generated only
from these stored facts — never from a fresh LLM call.
"""

from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.events import _require_device
from app.infrastructure.database import get_db
from app.infrastructure.models import DeviceToken, RecommendationTrace, TraceItem

router = APIRouter(tags=["traces"])


class TraceItemResponse(BaseModel):
    track_id: str
    title: str
    artist: str
    keyword_score: int
    final_rank: int | None
    passed_all_filters: bool
    exclusion_reason: str | None
    matched_keywords: list[str]
    reason_codes: list[str]


class TraceResponse(BaseModel):
    trace_id: str
    request_id: str | None
    intent_goal: str | None
    intent_scope: str | None
    intent_energy: str | None
    intent_duration_min: int | None
    intent_require_instrumental: bool | None
    intent_excluded_genres: list[str]
    intent_search_keywords: list[str]
    intent_confidence: float
    catalog_version: str | None
    candidate_count: int
    returned_count: int
    policy_version: str
    created_at: str
    items: list[TraceItemResponse]


@router.get("/traces/{trace_id}", response_model=TraceResponse)
async def get_trace(
    trace_id: str,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> TraceResponse:
    """Return one recommendation trace by ID.

    Only the user who triggered the request can read their own trace.
    """
    result = await db.execute(
        select(RecommendationTrace).where(RecommendationTrace.trace_id == trace_id)
    )
    trace = result.scalar_one_or_none()
    if trace is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trace not found.")
    if trace.user_id != device.user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    items_result = await db.execute(
        select(TraceItem)
        .where(TraceItem.trace_id == trace_id)
        .order_by(TraceItem.final_rank.nulls_last(), TraceItem.keyword_score.desc())
    )
    items = list(items_result.scalars().all())

    return TraceResponse(
        trace_id=trace.trace_id,
        request_id=trace.request_id,
        intent_goal=trace.intent_goal,
        intent_scope=trace.intent_scope,
        intent_energy=trace.intent_energy,
        intent_duration_min=trace.intent_duration_min,
        intent_require_instrumental=trace.intent_require_instrumental,
        intent_excluded_genres=_load_json_list(trace.intent_excluded_genres),
        intent_search_keywords=_load_json_list(trace.intent_search_keywords),
        intent_confidence=trace.intent_confidence,
        catalog_version=trace.catalog_version,
        candidate_count=trace.candidate_count,
        returned_count=trace.returned_count,
        policy_version=trace.policy_version,
        created_at=trace.created_at.isoformat(),
        items=[
            TraceItemResponse(
                track_id=item.track_id,
                title=item.title,
                artist=item.artist,
                keyword_score=item.keyword_score,
                final_rank=item.final_rank,
                passed_all_filters=(
                    item.passed_session_eligible
                    and item.passed_instrumental_filter
                    and item.passed_genre_exclusion
                ),
                exclusion_reason=item.exclusion_reason,
                matched_keywords=_load_json_list(item.matched_keywords),
                reason_codes=_load_json_list(item.reason_codes),
            )
            for item in items
        ],
    )


def _load_json_list(raw: str) -> list[str]:
    try:
        val = json.loads(raw or "[]")
        return val if isinstance(val, list) else []
    except (json.JSONDecodeError, TypeError):
        return []
