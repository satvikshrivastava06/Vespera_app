"""Legacy explore feed endpoint."""

from __future__ import annotations

import asyncio
from fastapi import APIRouter
from app.schemas.feed import ExploreFeedResponse
from app.legacy.home_feed import _spotify_category, _spotify_playlist

router = APIRouter(tags=["legacy"])


@router.get("/explore_feed", response_model=ExploreFeedResponse)
async def get_explore_feed() -> ExploreFeedResponse:
    results = await asyncio.gather(
        _spotify_category("toplists", limit=10, playlist=True),
        _spotify_playlist("37i9dQZEVXbMDoHDwVN2tF", limit=12),
        return_exceptions=True,
    )
    rows = [r if not isinstance(r, Exception) else [] for r in results]
    return ExploreFeedResponse(
        trending_events=rows[0],
        personalized_mixes=rows[1],
        categories=["Hyperpop", "Chill", "Lofi", "Techno", "Classical", "Indie"],
    )
