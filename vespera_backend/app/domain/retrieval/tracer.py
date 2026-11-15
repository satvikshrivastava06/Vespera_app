"""Recommendation trace persistence — VSP-011.

Every Twilight agent request that runs retrieval produces a
``RecommendationTrace`` row + one ``TraceItem`` per candidate.

The trace is the source of truth for all displayed explanations
(roadmap Gate 5 requirement): "every returned item has a persisted
candidate/filter/score/rank/plan trace."

Nothing in the explanation layer may be generated fresh from an LLM;
it must be regenerated from these stored fields.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.retrieval.retriever import CandidateResult, POLICY_VERSION
from app.infrastructure.models import RecommendationTrace, TraceItem
from app.schemas.intent import CompiledIntent

log = logging.getLogger(__name__)


async def persist_trace(
    trace_id: str,
    request_id: str | None,
    user_id: str,
    intent: CompiledIntent,
    candidates: list[CandidateResult],
    catalog_version: str | None,
    db: AsyncSession,
) -> RecommendationTrace:
    """Write one RecommendationTrace + N TraceItem rows.

    ``candidates`` should be the full list returned by ``retrieve()``
    (passing AND excluded) so the trace is complete.  ``final_rank`` is
    set only for passing candidates, in score order.
    """
    passing = [
        c for c in candidates
        if c.passed_genre_exclusion and c.passed_instrumental_filter
    ]
    returned = passing  # VSP-012 may further trim; for now all passing are returned

    trace = RecommendationTrace(
        trace_id=trace_id,
        request_id=request_id,
        user_id=user_id,
        intent_goal=intent.goal[:255] if intent.goal else None,
        intent_scope=intent.scope.value if intent.scope else None,
        intent_energy=intent.energy.value if intent.energy else None,
        intent_duration_min=intent.duration_min,
        intent_require_instrumental=intent.require_instrumental,
        intent_excluded_genres=json.dumps(intent.excluded_genres),
        intent_search_keywords=json.dumps(intent.search_keywords),
        intent_confidence=float(intent.confidence),
        catalog_version=catalog_version,
        candidate_count=len(candidates),
        returned_count=len(returned),
        policy_version=POLICY_VERSION,
        created_at=datetime.now(timezone.utc),
    )
    db.add(trace)
    await db.flush()  # populate trace.id so FK works

    # Build rank map for passing candidates
    rank_map = {c.track_id: i + 1 for i, c in enumerate(passing)}

    for c in candidates:
        item = TraceItem(
            trace_id=trace_id,
            track_id=c.track_id,
            title=c.title,
            artist=c.artist,
            keyword_score=c.keyword_score,
            final_rank=rank_map.get(c.track_id),
            passed_session_eligible=c.passed_session_eligible,
            passed_instrumental_filter=c.passed_instrumental_filter,
            passed_genre_exclusion=c.passed_genre_exclusion,
            exclusion_reason=c.exclusion_reason,
            matched_keywords=json.dumps(c.matched_keywords),
            reason_codes=json.dumps(c.reason_codes),
        )
        db.add(item)

    await db.flush()
    log.debug(
        "Trace %s: %d candidates, %d returned, policy=%s",
        trace_id, len(candidates), len(returned), POLICY_VERSION,
    )
    return trace
