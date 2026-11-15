"""Legacy home feed endpoint — pre-VSP-003 Spotify/YT feeds.

Retained for the existing Flutter home screen which still uses these
endpoints.  New code should use /api/v1/sessions instead.
"""

from __future__ import annotations

import asyncio
import datetime
import os
from typing import List, Optional

from fastapi import APIRouter, Header

from app.config import settings
from app.schemas.feed import HomeFeedResponse, NewsItem, PlaylistItem, UserRanking

router = APIRouter(tags=["legacy"])

# ── Provider clients (optional — degrade gracefully when missing) ─────────────

def _get_spotify():
    try:
        import spotipy
        from spotipy.oauth2 import SpotifyClientCredentials
        cid = settings.SPOTIPY_CLIENT_ID
        sec = settings.SPOTIPY_CLIENT_SECRET
        if not cid or not sec:
            return None
        return spotipy.Spotify(
            client_credentials_manager=SpotifyClientCredentials(
                client_id=cid, client_secret=sec
            )
        )
    except Exception:
        return None


def _get_ytmusic():
    try:
        from ytmusicapi import YTMusic
        return YTMusic()
    except Exception:
        return None


_spotify = _get_spotify()
_ytmusic = _get_ytmusic()


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _yt_search(query: str, limit: int = 5, search_filter: str = "songs") -> List[PlaylistItem]:
    items: List[PlaylistItem] = []
    if _ytmusic:
        try:
            yt_filter = "playlists" if search_filter == "playlists" else "songs"
            results = _ytmusic.search(query, filter=yt_filter, limit=limit)
            for v in results:
                art = v["artists"][0]["name"] if v.get("artists") else "Artist"
                img = (v.get("thumbnails") or [{}])[-1].get("url", "")
                items.append(PlaylistItem(
                    title=v.get("title", "Track"),
                    subtitle=art,
                    image_url=img,
                    search_query=f"{v.get('title', '')} {art} audio",
                    audio_id=v.get("videoId") or v.get("browseId") or "",
                ))
            if items:
                return items
        except Exception:
            pass

    try:
        from youtubesearchpython.__future__ import VideosSearch
        s = VideosSearch(query, limit=limit)
        result = await s.next()
        for v in (result.get("result") or []):
            thumbs = v.get("thumbnails") or [{}]
            items.append(PlaylistItem(
                title=str(v.get("title", "Track"))[:60],
                subtitle=(v.get("channel") or {}).get("name", "YouTube"),
                image_url=thumbs[0].get("url", ""),
                search_query=f"{v.get('title', '')} audio",
                audio_id=v.get("id", ""),
            ))
    except Exception:
        pass
    return items


async def _spotify_category(cat: str, limit: int = 5, playlist: bool = False) -> List[PlaylistItem]:
    if not _spotify:
        return await _yt_search(
            f"Popular {cat} {'playlists' if playlist else 'hits'} 2026",
            limit,
            "playlists" if playlist else "songs",
        )
    try:
        loop = asyncio.get_event_loop()
        res = await loop.run_in_executor(
            None, lambda: _spotify.category_playlists(category_id=cat, limit=limit)
        )
        return [
            PlaylistItem(
                title=p["name"],
                subtitle=(p.get("description") or "")[:40],
                image_url=p["images"][0]["url"] if p.get("images") else "",
                search_query=p["name"],
            )
            for p in res["playlists"]["items"]
        ]
    except Exception:
        return await _yt_search(f"Popular {cat} music", limit)


async def _spotify_playlist(pid: str, limit: int = 5) -> List[PlaylistItem]:
    if not _spotify:
        return await _yt_search("Global Top 50 Hits 2026", limit)
    try:
        loop = asyncio.get_event_loop()
        res = await loop.run_in_executor(
            None, lambda: _spotify.playlist_tracks(pid, limit=limit)
        )
        items = []
        for item in res.get("items") or []:
            t = item.get("track")
            if not t:
                continue
            art = t["artists"][0]["name"] if t.get("artists") else "Artist"
            img = t["album"]["images"][0]["url"] if t.get("album", {}).get("images") else ""
            items.append(PlaylistItem(
                title=t["name"], subtitle=art, image_url=img,
                search_query=f"{t['name']} {art} audio",
            ))
        return items
    except Exception:
        return await _yt_search("Top Billboard Hits 2026", limit)


async def _spotify_new_releases(limit: int = 5) -> List[PlaylistItem]:
    if not _spotify:
        return await _yt_search("New Music Friday 2026", limit)
    try:
        loop = asyncio.get_event_loop()
        res = await loop.run_in_executor(None, lambda: _spotify.new_releases(limit=limit))
        return [
            PlaylistItem(
                title=a["name"],
                subtitle=a["artists"][0]["name"] if a.get("artists") else "",
                image_url=a["images"][0]["url"] if a.get("images") else "",
                search_query=f"{a['name']} audio",
            )
            for a in res["albums"]["items"]
        ]
    except Exception:
        return await _yt_search("Fresh new music releases 2026", limit)


def _groq_vibe(time_ctx: str, weather: str):
    from app.config import settings
    if not settings.GROQ_API_KEY:
        return "Calibrating your rhythmic atmosphere...", ["pop", "chill"]
    try:
        from groq import Groq
        client = Groq(api_key=settings.GROQ_API_KEY)
        resp = client.chat.completions.create(
            messages=[{"role": "user", "content": (
                f"Analyze context (Time: {time_ctx}, Weather: {weather}) for Vespera. "
                "Output MESSAGE: [concise status] and CATEGORIES: [comma separated like 'pop,chill']."
            )}],
            model=settings.GROQ_MODEL,
            temperature=0.7,
        )
        raw = resp.choices[0].message.content
        msg = raw.split("MESSAGE:")[1].split("CATEGORIES:")[0].strip()
        cats = [c.strip() for c in raw.split("CATEGORIES:")[1].strip().split(",")]
        return msg, cats
    except Exception:
        return "Calibrating your rhythmic atmosphere...", ["pop", "chill"]


# ── Route ─────────────────────────────────────────────────────────────────────

@router.get("/home_feed", response_model=HomeFeedResponse)
async def get_home_feed(
    local_time: Optional[str] = Header(None),
    weather: Optional[str] = Header(None),
) -> HomeFeedResponse:
    hour = datetime.datetime.now().hour
    time_ctx = (
        "morning" if 5 <= hour < 12 else
        "afternoon" if 12 <= hour < 17 else
        "evening" if 17 <= hour < 21 else
        "late night"
    )
    greeting = f"Good {time_ctx}"
    ai_msg, cats = _groq_vibe(time_ctx, weather or "Clear")
    if len(cats) < 2:
        cats = ["pop", "chill"]

    results = await asyncio.gather(
        _spotify_category(cats[0], limit=8, playlist=True),
        _spotify_playlist("37i9dQZF1DX4WYpdVIPcmO", limit=8),
        _spotify_category(cats[1], limit=8),
        _spotify_playlist("37i9dQZEVXbMDoHDwVN2tF", limit=8),
        _spotify_new_releases(limit=8),
        return_exceptions=True,
    )
    rows = [r if not isinstance(r, Exception) else [] for r in results]

    return HomeFeedResponse(
        greeting=greeting,
        ai_message=ai_msg,
        rankings=[],
        popular_playlists=rows[0],
        jump_back_in=rows[1],
        quick_picks=rows[2],
        trending_now=rows[3],
        new_releases=rows[4],
        news=[
            NewsItem(
                category="TRENDING",
                title="Global Hits 2026",
                subtitle="The sound of the future is here.",
                image_url="https://images.unsplash.com/photo-1459749411175-04bf5292ceea",
            ),
            NewsItem(
                category="EXCLUSIVE",
                title="Vespera Spatial Audio",
                subtitle="Experience music like never before.",
                image_url="https://images.unsplash.com/photo-1598488035139-bdbb2231ce04",
            ),
        ],
    )
