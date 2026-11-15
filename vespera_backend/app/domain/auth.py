"""Anonymous device-bound token lifecycle.

Design (Appendix A7 of the roadmap):
  1. ``create_anonymous_token`` generates a cryptographically random opaque token.
  2. Only the SHA-256 hex digest is stored in ``device_tokens``.
  3. The raw token is returned to the client once and never persisted.
  4. ``authenticate_token`` looks up the hash and returns the pseudonymous user_id.
  5. user_id is always server-derived — callers must never trust a JSON-supplied value.
"""

from __future__ import annotations

import hashlib
import secrets
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.models import DeviceToken


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


async def create_anonymous_token(db: AsyncSession) -> tuple[str, str]:
    """Create a new anonymous device-bound token.

    Returns ``(raw_token, user_id)``.  The raw token is never stored; the caller
    must deliver it to the client immediately and never log it.
    """
    raw = secrets.token_urlsafe(32)
    token_hash = _hash_token(raw)
    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    record = DeviceToken(
        token_hash=token_hash,
        user_id=user_id,
        created_at=now,
        last_seen_at=now,
        revoked=False,
    )
    db.add(record)
    await db.flush()  # get DB errors before the response is sent
    return raw, user_id


async def authenticate_token(raw: str, db: AsyncSession) -> DeviceToken | None:
    """Return the ``DeviceToken`` row for a valid, non-revoked token hash.

    Returns ``None`` when the token is unknown or revoked.
    Updates ``last_seen_at`` as a side-effect.
    """
    token_hash = _hash_token(raw)
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.token_hash == token_hash,
            DeviceToken.revoked == False,  # noqa: E712
        )
    )
    record = result.scalar_one_or_none()
    if record is None:
        return None
    record.last_seen_at = datetime.now(timezone.utc)
    return record
