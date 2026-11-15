"""Outbound HTTP helpers: 403/429 backoff for provider APIs."""

from __future__ import annotations

import time
from collections.abc import Callable

import httpx

Retryable = {403, 429, 502, 503}


def get_with_backoff(
    client: httpx.Client,
    url: str,
    *,
    params: dict | None = None,
    headers: dict | None = None,
    attempts: int = 4,
    sleep: Callable[[float], None] = time.sleep,
) -> httpx.Response:
    last_error: Exception | None = None
    delay = 1.0
    for _ in range(attempts):
        try:
            response = client.get(url, params=params, headers=headers, timeout=20.0)
        except httpx.HTTPError as exc:
            last_error = exc
            sleep(delay)
            delay = min(delay * 2, 16)
            continue
        if response.status_code in Retryable:
            retry_after = response.headers.get("Retry-After")
            wait = float(retry_after) if retry_after and retry_after.isdigit() else delay
            sleep(min(wait, 30))
            delay = min(delay * 2, 16)
            last_error = httpx.HTTPStatusError(
                f"HTTP {response.status_code}",
                request=response.request,
                response=response,
            )
            continue
        return response
    if last_error:
        raise last_error
    raise RuntimeError("provider request failed")
