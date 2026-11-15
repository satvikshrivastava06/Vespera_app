"""Pydantic schemas for VSP-007 auth and events endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Literal, Optional

from pydantic import BaseModel, Field, UUID4


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------


class AnonymousTokenResponse(BaseModel):
    """Returned once to the client on first install. The raw token is never re-exposed."""

    token: str = Field(description="Opaque device-bound token. Store in secure storage.")
    user_id: str = Field(description="Stable pseudonymous identity derived from the token.")


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

EventType = Literal[
    "session_created",
    "impression",
    "start",
    "heartbeat",
    "pause",
    "complete",
    "skip",
    "save",
    "replay",
    "explicit_feedback",
]

FeedbackReason = Literal[
    "not_my_taste",
    "wrong_context",
    "too_energetic",
    "too_slow",
    "too_familiar",
    "lyrics",
    "already_heard",
    "other",
]

SourceSurface = Literal["home", "twilight", "search", "queue"]


class EventIn(BaseModel):
    """Body for POST /api/v1/events.

    ``event_id`` is a client-generated UUID4 used for idempotency.
    ``user_id`` must NOT be supplied by the client — it is derived from the token.
    ``occurred_at_utc`` defaults to now if omitted.
    """

    event_id: UUID4 = Field(default_factory=uuid.uuid4)
    # user_id intentionally absent — always server-derived.
    session_id: Optional[UUID4] = None
    track_id: Optional[str] = None
    event_type: EventType
    position_ms: Optional[int] = Field(default=None, ge=0)
    duration_ms: Optional[int] = Field(default=None, ge=0)
    feedback_reason: Optional[FeedbackReason] = None
    context_id: Optional[UUID4] = None
    source_surface: Optional[SourceSurface] = None
    request_id: Optional[UUID4] = None
    occurred_at_utc: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )


class EventAck(BaseModel):
    """Idempotent acknowledgement returned for every accepted event."""

    event_id: str
    row_id: int
    accepted: bool = True
