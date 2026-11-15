"""In-process sliding window. Correct for a single worker only."""

from __future__ import annotations

import time
from collections import defaultdict, deque

from fastapi import HTTPException


class SlidingWindowLimiter:
    def __init__(self, limit: int, window_s: int) -> None:
        self.limit = limit
        self.window_s = window_s
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        hits = self._hits[key]
        while hits and now - hits[0] > self.window_s:
            hits.popleft()
        if len(hits) >= self.limit:
            return False
        hits.append(now)
        if len(self._hits) > 10_000:
            for stale in [k for k, v in self._hits.items() if not v or now - v[-1] > self.window_s]:
                del self._hits[stale]
        return True

    def wait_s(self, key: str) -> int:
        hits = self._hits[key]
        if not hits:
            return 1
        now = time.monotonic()
        return max(1, int(self.window_s - (now - hits[0])))

    def check(self, key: str) -> None:
        if not self.allow(key):
            raise HTTPException(
                429,
                "Rate limit exceeded",
                headers={"Retry-After": str(self.wait_s(key))},
            )
