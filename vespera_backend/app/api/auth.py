"""POST /api/v1/auth/anonymous

Issues an opaque device-bound token on first install.  The token hash is
stored server-side; the raw token is returned once and never logged.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.auth import create_anonymous_token
from app.infrastructure.database import get_db
from app.schemas.events import AnonymousTokenResponse

router = APIRouter(tags=["auth"])


@router.post("/auth/anonymous", response_model=AnonymousTokenResponse, status_code=201)
async def bootstrap_anonymous_token(db: AsyncSession = Depends(get_db)) -> AnonymousTokenResponse:
    """Create a new anonymous device-bound token.

    Call this once per app installation and store the returned token in
    platform secure storage (flutter_secure_storage).  Attach it to all
    subsequent requests in the ``X-Device-Token`` header.
    """
    raw_token, user_id = await create_anonymous_token(db)
    return AnonymousTokenResponse(token=raw_token, user_id=user_id)
