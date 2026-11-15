"""Session and feedback schemas — VSP-012."""

from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field


# ── Session creation ──────────────────────────────────────────────────────────

class CreateSessionRequest(BaseModel):
    """POST /api/v1/sessions body."""
    text: str = Field(min_length=1, max_length=2000, description="Natural-language listening intent.")
    seed_track_ids: list[str] = Field(
        default_factory=list,
        max_length=5,
        description="3-5 track IDs selected by the user as seed tracks.",
    )
    request_id: Optional[str] = None


class QueueItemResponse(BaseModel):
    track_id: str
    title: str
    artist: str
    image_url: Optional[str] = None
    audio_url: Optional[str] = None
    jamendo_share_url: Optional[str] = None
    playable_ms: int
    position: int
    is_seed: bool
    in_seed_neighborhood: bool
    reason_codes: list[str] = Field(default_factory=list)


class SessionResponse(BaseModel):
    session_id: str
    plan_version: int
    intent_goal: Optional[str] = None
    intent_scope: Optional[str] = None
    intent_duration_min: Optional[int] = None
    total_planned_ms: int
    instrumental_ms: int
    instrumental_pct: float
    quota_satisfied: bool
    unsatisfied_note: Optional[str] = None
    state: str
    queue: list[QueueItemResponse] = Field(default_factory=list)
    trace_id: Optional[str] = None


# ── Feedback / skip ───────────────────────────────────────────────────────────

FeedbackReasonLiteral = Literal[
    "not_my_taste", "wrong_context", "too_energetic",
    "too_slow", "too_familiar", "lyrics", "already_heard", "other",
]


class SessionFeedbackRequest(BaseModel):
    """POST /api/v1/sessions/{id}/feedback body."""
    track_id: str = Field(description="Track being skipped / providing feedback on.")
    feedback_reason: FeedbackReasonLiteral
    position_ms: Optional[int] = Field(default=None, ge=0)


class FeedbackResponse(BaseModel):
    session_id: str
    plan_version: int
    replanned: bool
    new_queue: list[QueueItemResponse] = Field(default_factory=list)
    message: str
