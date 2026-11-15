"""Apple iTunes Search: catalog lookup and external handoff only.

Promotional preview URLs are never returned as session audio. playable_ms is 0.
"""

from __future__ import annotations

import time
from datetime import datetime, timezone

import httpx

from app.infrastructure.http import get_with_backoff
from app.infrastructure.limiter import SlidingWindowLimiter
from app.schemas.track import PlaybackMode, ProviderTrack

ITUNES_SEARCH_URL = "https://itunes.apple.com/search"


class AppleSearchAdapter:
    def __init__(
        self,
        *,
        client: httpx.Client | None = None,
        limiter: SlidingWindowLimiter | None = None,
        sleep=time.sleep,
    ) -> None:
        self._client = client or httpx.Client()
        self._owns_client = client is None
        # Apple documents ~20 Search API calls/minute/IP.
        self._limiter = limiter or SlidingWindowLimiter(20, 60)
        self._cache: dict[str, ProviderTrack] = {}
        self._sleep = sleep

    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def lookup_handoff(self, term: str) -> ProviderTrack | None:
        query = " ".join(term.split())
        if not query:
            return None
        cached = self._cache.get(query.lower())
        if cached is not None:
            return cached
        if not self._limiter.allow("itunes-search"):
            self._sleep(self._limiter.wait_s("itunes-search"))
            if not self._limiter.allow("itunes-search"):
                raise RuntimeError("Apple Search rate limit exceeded")
        params = {
            "term": query,
            "media": "music",
            "entity": "song",
            "limit": 1,
        }
        response = get_with_backoff(
            self._client,
            ITUNES_SEARCH_URL,
            params=params,
            sleep=self._sleep,
        )
        response.raise_for_status()
        results = (response.json() or {}).get("results") or []
        if not results:
            return None
        row = results[0]
        track_id = str(row.get("trackId") or "")
        deep_link = row.get("trackViewUrl")
        if not deep_link:
            return None
        track = ProviderTrack(
            provider="apple",
            provider_track_id=track_id or query,
            playback_mode=PlaybackMode.HANDOFF,
            deep_link=deep_link,
            playable_ms=0,
            preview_asset_ms=0,
            session_eligible=False,
            verified_at=datetime.now(timezone.utc),
        )
        self._cache[query.lower()] = track
        return track
