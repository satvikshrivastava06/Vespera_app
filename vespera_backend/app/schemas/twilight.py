"""Typed request/response schemas for POST /api/v1/twilight/agent.

The shape mirrors the roadmap Section 10 contract.  VSP-009 wires the
endpoint itself; VSP-010 adds the real intent compiler behind it.  For now
the endpoint returns a structured stub so Flutter can test the full request
path end-to-end without blocking on the LLM work.
"""

from __future__ import annotations

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TwilightMode(str, Enum):
    CHAT = "chat"
    SUGGESTION = "suggestion"
    SEMANTIC_SEARCH = "semantic_search"


class TwilightRequestStatus(str, Enum):
    READY = "ready"
    NEEDS_CLARIFICATION = "needs_clarification"
    PARTIAL = "partial"
    ERROR = "error"


class TwilightRequest(BaseModel):
    """Body for POST /api/v1/twilight/agent.

    ``mode`` selects the interaction surface (chat, suggestion card tap,
    semantic search).  ``text`` is the natural-language input.  Optional
    context fields are reserved for future gates.
    ``request_id`` is a client-generated UUID for idempotency and tracing.
    """

    text: str = Field(min_length=1, max_length=2000)
    mode: TwilightMode = TwilightMode.CHAT
    request_id: Optional[str] = None
    # Reserved for VSP-010: session / context fields
    session_id: Optional[str] = None
    context: Optional[dict] = None


class TwilightTrackResult(BaseModel):
    """Minimal track shape returned in a Twilight agent response."""

    track_id: str
    title: str
    artist: str
    playback_mode: str
    session_eligible: bool
    playable_ms: int
    audio_url: Optional[str] = None
    jamendo_share_url: Optional[str] = None
    image_url: Optional[str] = None
    reason_codes: list[str] = Field(default_factory=list)


class TwilightResponse(BaseModel):
    """Typed response for the Twilight agent endpoint.

    ``schema_version`` lets Flutter reject incompatible future shapes.
    ``status`` drives UI state: ready → show results, needs_clarification →
    prompt the user, partial → show what we have with a warning,
    error → show recoverable error UI.
    """

    schema_version: str = "1.0"
    request_id: Optional[str] = None
    trace_id: Optional[str] = None
    status: TwilightRequestStatus
    message: str
    # Populated by VSP-010 intent compiler.
    intent_goal: Optional[str] = None
    intent_scope: Optional[str] = None
    intent_energy: Optional[str] = None
    intent_duration_min: Optional[int] = None
    intent_require_instrumental: Optional[bool] = None
    intent_excluded_genres: list[str] = Field(default_factory=list)
    intent_negations: list[str] = Field(default_factory=list)
    # Populated once VSP-012 (session planner) is wired.
    session_id: Optional[str] = None
    # Track results available from the catalog.
    tracks: list[TwilightTrackResult] = Field(default_factory=list)
    unverified_constraints: list[str] = Field(default_factory=list)
    next_actions: list[str] = Field(default_factory=list)
