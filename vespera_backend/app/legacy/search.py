"""Legacy search endpoint."""

from __future__ import annotations

from fastapi import APIRouter
from app.schemas.feed import PlaylistItem
from app.legacy.home_feed import _ytmusic

router = APIRouter(tags=["legacy"])


@router.get("/search", response_model=list[PlaylistItem])
async def search_music(query: str, search_type: str = "all") -> list[PlaylistItem]:
    if not query or len(query.strip()) < 1:
        return []
    yt_filter = "playlists" if search_type == "playlists" else "songs"
    items: list[PlaylistItem] = []
    if _ytmusic:
        try:
            import asyncio
            raw = await asyncio.to_thread(_ytmusic.search, query, filter=yt_filter, limit=20)
            for item in raw:
                thumbs = item.get("thumbnails") or []
                img = thumbs[-1]["url"] if thumbs else ""
                arts = item.get("artists") or []
                sub = arts[0].get("name", "Artist") if arts else "Artist"
                items.append(PlaylistItem(
                    title=item.get("title", "Track"),
                    subtitle=sub,
                    image_url=img,
                    search_query=f"{item.get('title', '')} {sub} audio",
                    audio_id=item.get("videoId") or item.get("playlistId") or "",
                ))
            if items:
                return items
        except Exception:
            pass

    try:
        from youtubesearchpython.__future__ import VideosSearch
        s = VideosSearch(f"{query} audio", limit=10)
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
