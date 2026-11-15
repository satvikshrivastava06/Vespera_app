"""Simple in-memory rate limiter for auth and Twilight endpoints.

Uses a sliding-window counter per (IP, endpoint) key. Production deployments
behind a proxy must set uvicorn --proxy-headers so request.client.host reflects
the real client IP (X-Forwarded-For), not the proxy's internal address.
"""

from __future__ import annotations

import os
import time
from collections import defaultdict
from typing import DefaultDict, Tuple

from fastapi import HTTPException, Request

# {(ip, endpoint): [(timestamp, count), ...]}
_calls: DefaultDict[Tuple[str, str], list[Tuple[float, int]]] = defaultdict(list)

# Allow tests to bypass rate limiting
_ENABLED = os.environ.get("RATE_LIMIT_ENABLED", "true").lower() == "true"


async def check_rate_limit(
    request: Request,
    endpoint: str,
    max_calls: int,
    window_seconds: int,
) -> None:
    """Raise HTTPException 429 if (client_ip, endpoint) exceeded max_calls in the window.

    Args:
        request: FastAPI request containing client IP
        endpoint: Unique identifier for this rate-limited endpoint
        max_calls: Maximum allowed calls in the window
        window_seconds: Sliding window size in seconds

    Raises:
        HTTPException: 429 Too Many Requests if limit exceeded
    """
    if not _ENABLED:
        return
    
    client_ip = request.client.host if request.client else "unknown"
    key = (client_ip, endpoint)
    now = time.time()
    cutoff = now - window_seconds

    # Remove expired entries
    _calls[key] = [(ts, cnt) for ts, cnt in _calls[key] if ts > cutoff]

    # Count recent calls
    total = sum(cnt for _, cnt in _calls[key])

    if total >= max_calls:
        raise HTTPException(
            status_code=429,
            detail=f"Rate limit exceeded: {max_calls} requests per {window_seconds}s",
            headers={"Retry-After": str(window_seconds)},
        )

    # Record this call
    _calls[key].append((now, 1))
