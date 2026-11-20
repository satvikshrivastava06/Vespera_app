"""POST /api/v1/auth/anonymous

Issues an opaque device-bound token on first install.  The token hash is
stored server-side; the raw token is returned once and never logged.

Rate limit: 5 requests per minute per IP (prevents token-flooding attacks).
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.auth import create_anonymous_token
from app.infrastructure.database import get_db
from app.infrastructure.rate_limit import check_rate_limit
from app.schemas.events import AnonymousTokenResponse

router = APIRouter(tags=["auth"])


@router.post("/auth/anonymous", response_model=AnonymousTokenResponse, status_code=201)
async def bootstrap_anonymous_token(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AnonymousTokenResponse:
    """Create a new anonymous device-bound token.

    Call this once per app installation and store the returned token in
    platform secure storage (flutter_secure_storage).  Attach it to all
    subsequent requests in the ``X-Device-Token`` header.
    """
    await check_rate_limit(request, "auth_anonymous", max_calls=5, window_seconds=60)
    # Spoof-proof ceiling on token minting, independent of the caller's IP.
    await check_rate_limit(
        request, "auth_anonymous_global", max_calls=120, window_seconds=3600, key="global"
    )
    raw_token, user_id = await create_anonymous_token(db)
    return AnonymousTokenResponse(token=raw_token, user_id=user_id)
