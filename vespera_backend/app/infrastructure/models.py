"""SQLAlchemy ORM models for VSP-007, VSP-011, and VSP-012.

Tables:
  device_tokens        — anonymous device-bound auth tokens (hash only)
  listening_event      — append-only behavioral evidence
  catalog_track_index  — denormalised FTS-ready catalog rows (VSP-011)
  recommendation_trace — per-request candidate/filter/score snapshot (VSP-011)
  trace_item           — per-candidate row inside a trace (VSP-011)
  listening_session    — session contract + state (VSP-012)
  session_queue_item   — ordered queue rows with playable_ms accounting (VSP-012)
  queue_plan_version   — append-only plan history for replan auditing (VSP-012)
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean, DateTime, Float, ForeignKey, Index,
    Integer, String, Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


# ── VSP-007 ──────────────────────────────────────────────────────────────────

class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), unique=True, nullable=False, index=True, default=_uuid)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    events: Mapped[list[ListeningEvent]] = relationship(
        "ListeningEvent", back_populates="device", lazy="raise"
    )


class ListeningEvent(Base):
    __tablename__ = "listening_event"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    event_id: Mapped[str] = mapped_column(String(36), unique=True, nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("device_tokens.user_id"), nullable=False, index=True)
    session_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    track_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    event_type: Mapped[str] = mapped_column(String(32), nullable=False)
    position_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    duration_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    feedback_reason: Mapped[str | None] = mapped_column(String(64), nullable=True)
    context_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    source_surface: Mapped[str | None] = mapped_column(String(32), nullable=True)
    request_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    occurred_at_utc: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    received_at_utc: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    device: Mapped[DeviceToken] = relationship("DeviceToken", back_populates="events", lazy="raise")


# ── VSP-011 ──────────────────────────────────────────────────────────────────

class CatalogTrackIndex(Base):
    """Denormalised, FTS-ready snapshot of catalog tracks.

    Populated by the catalog indexer at startup / on seed reload.
    One row per track.  Deleted and re-inserted on each full re-index.

    ``search_text`` is the concatenated, lowercased haystack used for
    LIKE-based substring search (SQLite) and tsvector GIN index (Postgres).
    ``tags_text`` stores the raw tag list for display / filter pass-through.
    """

    __tablename__ = "catalog_track_index"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    track_id: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(512), nullable=False)
    artist: Mapped[str] = mapped_column(String(512), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    jamendo_share_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    playable_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    session_eligible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    instrumental_label: Mapped[str | None] = mapped_column(String(64), nullable=True)
    license: Mapped[str | None] = mapped_column(Text, nullable=True)
    tags_text: Mapped[str] = mapped_column(Text, nullable=False, default="")
    # Concatenated haystack for FTS: title + artist + tags (lowercased)
    search_text: Mapped[str] = mapped_column(Text, nullable=False, default="")
    catalog_version: Mapped[str] = mapped_column(String(64), nullable=False, default="")
    indexed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        # Composite index to accelerate session_eligible + search_text lookups
        Index("ix_cti_eligible_search", "session_eligible", "search_text"),
    )


class RecommendationTrace(Base):
    """One recommendation trace per Twilight agent request.

    Records what the system decided and why, so every displayed explanation
    can be regenerated from stored facts rather than from LLM imagination.
    Every field here matches a roadmap Gate 5 / 7 requirement.
    """

    __tablename__ = "recommendation_trace"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    trace_id: Mapped[str] = mapped_column(String(36), unique=True, nullable=False, index=True, default=_uuid)
    request_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)

    # Intent compiler output (snapshot)
    intent_goal: Mapped[str | None] = mapped_column(Text, nullable=True)
    intent_scope: Mapped[str | None] = mapped_column(String(32), nullable=True)
    intent_energy: Mapped[str | None] = mapped_column(String(16), nullable=True)
    intent_duration_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    intent_require_instrumental: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    intent_excluded_genres: Mapped[str] = mapped_column(Text, nullable=False, default="")  # JSON list
    intent_search_keywords: Mapped[str] = mapped_column(Text, nullable=False, default="")  # JSON list
    intent_confidence: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # Retrieval context
    catalog_version: Mapped[str | None] = mapped_column(String(64), nullable=True)
    candidate_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    returned_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    policy_version: Mapped[str] = mapped_column(String(64), nullable=False, default="b0-keyword-v1")

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    items: Mapped[list[TraceItem]] = relationship(
        "TraceItem", back_populates="trace", lazy="raise", cascade="all, delete-orphan"
    )


class TraceItem(Base):
    """One candidate track evaluated within a recommendation trace.

    ``rank`` is 1-based; ``exclusion_reason`` is set only for filtered-out
    candidates so we can explain why a track was rejected.
    """

    __tablename__ = "trace_item"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    trace_id: Mapped[str] = mapped_column(String(36), ForeignKey("recommendation_trace.trace_id"), nullable=False, index=True)
    track_id: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(512), nullable=False)
    artist: Mapped[str] = mapped_column(String(512), nullable=False)

    # Scoring
    keyword_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    final_rank: Mapped[int | None] = mapped_column(Integer, nullable=True)   # None = excluded

    # Filter decisions
    passed_session_eligible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    passed_instrumental_filter: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    passed_genre_exclusion: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    exclusion_reason: Mapped[str | None] = mapped_column(String(128), nullable=True)

    # Explanation evidence
    matched_keywords: Mapped[str] = mapped_column(Text, nullable=False, default="")  # JSON list
    reason_codes: Mapped[str] = mapped_column(Text, nullable=False, default="")      # JSON list

    trace: Mapped[RecommendationTrace] = relationship("RecommendationTrace", back_populates="items", lazy="raise")


# ── VSP-012 ──────────────────────────────────────────────────────────────────

class ListeningSession(Base):
    """One adaptive listening session.

    ``state``: active | completed | abandoned
    ``plan_version``: increments on each replan so the history is auditable.
    ``total_planned_ms``: sum of playable_ms for all UNPLAYED queue items
    at plan creation — used to verify the 30-min acceptance criterion.
    ``instrumental_ms``: sum of playable_ms for verified-instrumental items
    in the initial plan — used to verify the 80% quota.
    """

    __tablename__ = "listening_session"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String(36), unique=True, nullable=False, index=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    trace_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    # Intent snapshot
    intent_goal: Mapped[str | None] = mapped_column(Text, nullable=True)
    intent_scope: Mapped[str | None] = mapped_column(String(32), nullable=True)
    intent_duration_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    intent_require_instrumental: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    seed_track_ids: Mapped[str] = mapped_column(Text, nullable=False, default="")  # JSON list

    # Plan accounting
    plan_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    total_planned_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    instrumental_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    state: Mapped[str] = mapped_column(String(16), nullable=False, default="active")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    queue_items: Mapped[list[SessionQueueItem]] = relationship(
        "SessionQueueItem", back_populates="session",
        lazy="raise", cascade="all, delete-orphan",
        order_by="SessionQueueItem.position",
    )
    plan_versions: Mapped[list[QueuePlanVersion]] = relationship(
        "QueuePlanVersion", back_populates="session",
        lazy="raise", cascade="all, delete-orphan",
    )


class SessionQueueItem(Base):
    """One track in a session queue.

    ``played``: True once the track has started.
    ``position``: 1-based order within the current plan version.
    ``is_seed``: True for the 3-5 user-selected seed tracks.
    ``in_seed_neighborhood``: True for the first 10-min arc.
    Only unplayed items are replanned; played items are immutable.
    """

    __tablename__ = "session_queue_item"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String(36), ForeignKey("listening_session.session_id"), nullable=False, index=True)
    track_id: Mapped[str] = mapped_column(String(255), nullable=False)
    title: Mapped[str] = mapped_column(String(512), nullable=False)
    artist: Mapped[str] = mapped_column(String(512), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    jamendo_share_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    playable_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    instrumental_label: Mapped[str | None] = mapped_column(String(64), nullable=True)

    position: Mapped[int] = mapped_column(Integer, nullable=False)
    plan_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    played: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_seed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    in_seed_neighborhood: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    reason_codes: Mapped[str] = mapped_column(Text, nullable=False, default="")  # JSON list

    session: Mapped[ListeningSession] = relationship("ListeningSession", back_populates="queue_items", lazy="raise")


class QueuePlanVersion(Base):
    """Append-only plan history — written on creation and each replan.

    Stores the ordered track_ids of the unplayed queue at the moment the
    plan was created so changes are auditable and reversible.
    """

    __tablename__ = "queue_plan_version"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String(36), ForeignKey("listening_session.session_id"), nullable=False, index=True)
    plan_version: Mapped[int] = mapped_column(Integer, nullable=False)
    trigger: Mapped[str] = mapped_column(String(64), nullable=False, default="initial")
    # Trigger details: feedback reason or "initial"
    trigger_detail: Mapped[str | None] = mapped_column(Text, nullable=True)
    # JSON array of track_ids in unplayed order at this plan version
    unplayed_track_ids: Mapped[str] = mapped_column(Text, nullable=False, default="")
    total_planned_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    session: Mapped[ListeningSession] = relationship("ListeningSession", back_populates="plan_versions", lazy="raise")
