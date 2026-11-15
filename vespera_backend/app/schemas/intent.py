"""Typed intent schema — output of the intent compiler (VSP-010).

A compiled intent is the validated policy object the rest of the system
enforces.  Every field is explicit: hard constraints are filters,
soft preferences are scored weights, unknown fields are surfaced rather
than quietly dropped.

The LLM must never produce final track titles or IDs.  It only produces
the structured intent; the retrieval + ranking layer picks real catalog
records.
"""

from __future__ import annotations

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class IntentScope(str, Enum):
    SESSION = "current_session"
    CONTEXT = "context"
    GLOBAL = "global_explicit_rule"


class MemoryAction(str, Enum):
    """What the system should do with this instruction across time."""
    SESSION_ONLY = "session_only"       # expires at session end
    UPDATE_CONTEXT = "update_context"   # update context preference
    CONFIRM_GLOBAL = "confirm_global"   # requires explicit user confirmation


class EnergyLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    ANY = "any"


class NoveltyLevel(str, Enum):
    FAMILIAR = "familiar"
    MIXED = "mixed"
    ADVENTUROUS = "adventurous"
    ANY = "any"


class CompiledIntent(BaseModel):
    """
    Structured output from the intent compiler.

    ``confidence`` is the compiler's self-assessed confidence [0.0–1.0]
    that it correctly interpreted the request.  Low confidence must surface
    ambiguities rather than silently picking the most likely interpretation.

    Hard constraints are enforced as filters; unknown metadata never satisfies
    a hard constraint silently.  Soft preferences become score weights.
    """

    # ── Goal ─────────────────────────────────────────────────────────────────
    goal: str = Field(description="Short human-readable listening goal, max 80 chars.")
    scope: IntentScope = IntentScope.SESSION
    memory_action: MemoryAction = MemoryAction.SESSION_ONLY

    # ── Duration ─────────────────────────────────────────────────────────────
    duration_min: Optional[int] = Field(
        default=None, ge=1, le=180,
        description="Requested session length in minutes."
    )

    # ── Hard constraints (enforced as catalog filters) ────────────────────────
    require_instrumental: Optional[bool] = Field(
        default=None,
        description="True = only tracks with verified instrumental label."
    )
    exclude_explicit: bool = False
    excluded_artists: list[str] = Field(default_factory=list)
    excluded_genres: list[str] = Field(default_factory=list)
    required_languages: list[str] = Field(default_factory=list)
    max_artist_repeats: Optional[int] = Field(default=None, ge=1)

    # ── Soft preferences (scored, not filtered) ───────────────────────────────
    preferred_genres: list[str] = Field(default_factory=list)
    preferred_artists: list[str] = Field(default_factory=list)
    energy: EnergyLevel = EnergyLevel.ANY
    novelty: NoveltyLevel = NoveltyLevel.ANY

    # ── Search keywords extracted for catalog retrieval ───────────────────────
    search_keywords: list[str] = Field(
        default_factory=list,
        description="2–6 catalog-safe keywords for retrieval. No invented track titles."
    )

    # ── Compiler metadata ─────────────────────────────────────────────────────
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    ambiguities: list[str] = Field(
        default_factory=list,
        description="Unresolved contradictions or unknown fields the user should clarify."
    )
    unverified_constraints: list[str] = Field(
        default_factory=list,
        description="Hard constraints that cannot be verified from catalog metadata."
    )
    negations_detected: list[str] = Field(
        default_factory=list,
        description="Explicit negations parsed (e.g. 'no vocals', 'not hip hop')."
    )
