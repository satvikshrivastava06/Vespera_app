"""POST /api/v1/events

Idempotent listening-event ingestion.  user_id is always derived from the
authenticated device token — the request body must not contain a user_id field.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.auth import authenticate_token
from app.domain.events import record_event
from app.infrastructure.database import get_db
from app.infrastructure.models import DeviceToken
from app.schemas.events import EventAck, EventIn

router = APIRouter(tags=["events"])


async def _require_device(
    x_device_token: str = Header(..., alias="X-Device-Token"),
    db: AsyncSession = Depends(get_db),
) -> DeviceToken:
    """FastAPI dependency: authenticate the X-Device-Token header."""
    device = await authenticate_token(x_device_token, db)
    if device is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or revoked device token.",
        )
    return device


@router.post("/events", response_model=EventAck, status_code=200)
async def ingest_event(
    payload: EventIn,
    device: DeviceToken = Depends(_require_device),
    db: AsyncSession = Depends(get_db),
) -> EventAck:
    """Record one listening event.  Duplicate ``event_id`` submissions return 200
    without creating a second row (idempotent).
    """
    try:
        row_id = await record_event(payload, device, db)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))
    return EventAck(event_id=str(payload.event_id), row_id=row_id)
