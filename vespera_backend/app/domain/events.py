"""Listening event ingestion with idempotency.

``record_event`` inserts one ``ListeningEvent`` row.  If a row with the same
``event_id`` already exists the call is a no-op and returns the existing row's
primary key — this makes the endpoint safe to retry.

user_id is always taken from the authenticated ``DeviceToken``; the caller
must never pass a client-supplied user_id directly.
"""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.models import DeviceToken, ListeningEvent
from app.schemas.events import EventIn

ALLOWED_EVENT_TYPES = frozenset(
    {
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
    }
)

ALLOWED_FEEDBACK_REASONS = frozenset(
    {
        "not_my_taste",
        "wrong_context",
        "too_energetic",
        "too_slow",
        "too_familiar",
        "lyrics",
        "already_heard",
        "other",
        None,
    }
)

ALLOWED_SURFACES = frozenset({"home", "twilight", "search", "queue", None})


async def record_event(
    payload: EventIn,
    device: DeviceToken,
    db: AsyncSession,
) -> int:
    """Persist one event idempotently.  Returns the row ``id``."""
    # Validate event_type against allow-list (defense-in-depth; schema also validates).
    if payload.event_type not in ALLOWED_EVENT_TYPES:
        raise ValueError(f"Unknown event_type: {payload.event_type!r}")

    if payload.feedback_reason not in ALLOWED_FEEDBACK_REASONS:
        raise ValueError(f"Unknown feedback_reason: {payload.feedback_reason!r}")

    if payload.source_surface not in ALLOWED_SURFACES:
        raise ValueError(f"Unknown source_surface: {payload.source_surface!r}")

    now = datetime.now(timezone.utc)

    # Idempotency: check existence before inserting so we never need to roll
    # back the shared session (which would break callers that share a
    # transaction, including test fixtures and Postgres savepoints).
    existing = await db.execute(
        select(ListeningEvent.id).where(
            ListeningEvent.event_id == str(payload.event_id)
        )
    )
    existing_id = existing.scalar_one_or_none()
    if existing_id is not None:
        return existing_id

    event = ListeningEvent(
        event_id=str(payload.event_id),
        user_id=device.user_id,  # always server-derived
        session_id=str(payload.session_id) if payload.session_id else None,
        track_id=payload.track_id,
        event_type=payload.event_type,
        position_ms=payload.position_ms,
        duration_ms=payload.duration_ms,
        feedback_reason=payload.feedback_reason,
        context_id=str(payload.context_id) if payload.context_id else None,
        source_surface=payload.source_surface,
        request_id=str(payload.request_id) if payload.request_id else None,
        occurred_at_utc=payload.occurred_at_utc,
        received_at_utc=now,
    )
    db.add(event)
    await db.flush()
    return event.id
