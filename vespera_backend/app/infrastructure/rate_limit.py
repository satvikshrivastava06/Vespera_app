"""Per-endpoint rate limiting for public routes.

In-process and single-worker only: every uvicorn worker keeps its own counters.

Environment:
  RATE_LIMIT_ENABLED  "true" (default) or "false". Read on every call.
  TRUSTED_PROXY_HOPS  0 (default): use the socket peer address.
                      n > 0: use the n-th entry counted from the RIGHT of
                      X-Forwarded-For, i.e. the address your own platform proxy
                      appended. Entries to its left are client-supplied and are
                      never trusted.
"""

from __future__ import annotations

import logging
import os

from fastapi import HTTPException, Request

from app.infrastructure.limiter import SlidingWindowLimiter

log = logging.getLogger("vespera.rate_limit")

_limiters: dict[tuple[str, int, int], SlidingWindowLimiter] = {}


def _enabled() -> bool:
    return os.environ.get("RATE_LIMIT_ENABLED", "true").lower() == "true"


def _proxy_hops() -> int:
    try:
        return max(0, int(os.environ.get("TRUSTED_PROXY_HOPS", "0") or 0))
    except ValueError:
        return 0


def client_ip(request: Request) -> str:
    hops = _proxy_hops()
    if hops:
        forwarded = [
            part.strip()
            for part in request.headers.get("x-forwarded-for", "").split(",")
            if part.strip()
        ]
        if len(forwarded) >= hops:
            return forwarded[-hops]
    return request.client.host if request.client else "unknown"


def reset_rate_limits() -> None:
    """Clear all counters (used by tests)."""
    _limiters.clear()


async def check_rate_limit(
    request: Request,
    endpoint: str,
    max_calls: int,
    window_seconds: int,
    key: str | None = None,
) -> None:
    """Raise 429 when ``key`` (default: the caller's IP) exceeds the limit for ``endpoint``."""
    if not _enabled():
        return
    limiter = _limiters.setdefault(
        (endpoint, max_calls, window_seconds),
        SlidingWindowLimiter(max_calls, window_seconds),
    )
    subject = key if key is not None else client_ip(request)
    if not limiter.allow(subject):
        log.warning(
            "Rate limit hit endpoint=%s subject=%s x-forwarded-for=%r",
            endpoint, subject, request.headers.get("x-forwarded-for"),
        )
        raise HTTPException(
            status_code=429,
            detail=f"Rate limit exceeded: {max_calls} requests per {window_seconds}s",
            headers={"Retry-After": str(limiter.wait_s(subject))},
        )
