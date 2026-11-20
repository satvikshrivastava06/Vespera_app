"""Catalog-backed Home, Explore and Search feeds (VSP-014).

Replaces the legacy Spotify / YouTube-scraping feeds. Only rights-cleared,
session-eligible catalog tracks are returned, so every card is playable.

Sections that would need data the app does not have (listening history, trend
data, release dates) are returned empty instead of being invented.
"""

from __future__ import annotations

import datetime
import hashlib
import re
from collections import Counter, defaultdict
from typing import Optional

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.database import get_db
from app.infrastructure.models import CatalogTrackIndex
from app.schemas.feed import ExploreFeedResponse, HomeFeedResponse, PlaylistItem

router = APIRouter(tags=["feeds"])

_MAX_ROWS = 500
_HOUR_RE = re.compile(r"(\d{1,2}):(\d{2})")
# The index stores tags whitespace-joined, so multi-word tags arrive as separate
# words. Very short or generic words are not useful as collection names.
_STOP_TAGS = {"and", "the", "for", "with", "music"}


def _hour_from_header(local_time: Optional[str]) -> int:
    value = (local_time or "").strip()
    if value:
        try:
            return datetime.datetime.fromisoformat(value).hour
        except ValueError:
            pass
        match = _HOUR_RE.search(value)
        if match:
            hour = int(match.group(1))
            lowered = value.lower()
            if "pm" in lowered and hour < 12:
                hour += 12
            elif "am" in lowered and hour == 12:
                hour = 0
            if 0 <= hour < 24:
                return hour
    return datetime.datetime.now(datetime.timezone.utc).hour


def _time_context(hour: int) -> str:
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 17:
        return "afternoon"
    if 17 <= hour < 21:
        return "evening"
    return "late night"


def _split_tags(tags_text: str) -> list[str]:
    seen: set[str] = set()
    tags: list[str] = []
    for raw in (tags_text or "").split():
        tag = raw.strip().lower()
        if len(tag) >= 3 and tag not in _STOP_TAGS and tag not in seen:
            seen.add(tag)
            tags.append(tag)
    return tags


def _escape_like(term: str) -> str:
    return term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _to_item(row: CatalogTrackIndex) -> PlaylistItem:
    return PlaylistItem(
        title=row.title,
        subtitle=row.artist,
        image_url=row.image_url or "",
        search_query="",
        audio_id=row.track_id,
        artist=row.artist,
        audio_url=row.audio_url,
        playable_ms=row.playable_ms,
        session_eligible=row.session_eligible,
        jamendo_share_url=row.jamendo_share_url,
    )


async def _eligible(db: AsyncSession) -> list[CatalogTrackIndex]:
    result = await db.execute(
        select(CatalogTrackIndex)
        .where(CatalogTrackIndex.session_eligible.is_(True))
        .where(CatalogTrackIndex.audio_url.is_not(None))
        .order_by(CatalogTrackIndex.track_id)
        .limit(_MAX_ROWS)
    )
    return list(result.scalars())


def _daily_pick(rows: list[CatalogTrackIndex], count: int, salt: str) -> list[CatalogTrackIndex]:
    """Deterministic selection that rotates once per UTC day."""
    today = datetime.datetime.now(datetime.timezone.utc).date().isoformat()
    ranked = sorted(
        rows,
        key=lambda r: hashlib.sha256(f"{today}:{salt}:{r.track_id}".encode()).hexdigest(),
    )
    return ranked[:count]


def _tag_collections(
    rows: list[CatalogTrackIndex], max_cards: int, min_tracks: int = 3
) -> list[PlaylistItem]:
    """One card per tag. A card plays the first track of its collection."""
    by_tag: dict[str, list[CatalogTrackIndex]] = defaultdict(list)
    for row in rows:
        for tag in _split_tags(row.tags_text):
            by_tag[tag].append(row)
    ranked = sorted(by_tag.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    cards: list[PlaylistItem] = []
    for tag, members in ranked:
        if len(members) < min_tracks:
            continue
        cards.append(
            _to_item(members[0]).model_copy(
                update={"title": tag.title(), "subtitle": f"{len(members)} tracks"}
            )
        )
        if len(cards) == max_cards:
            break
    return cards


@router.get("/home_feed", response_model=HomeFeedResponse)
async def get_home_feed(
    local_time: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
) -> HomeFeedResponse:
    context = _time_context(_hour_from_header(local_time))
    rows = await _eligible(db)
    return HomeFeedResponse(
        greeting=f"Good {context}",
        ai_message=f"Picks for your {context}." if rows else "No tracks are available yet.",
        rankings=[],
        popular_playlists=_tag_collections(rows, max_cards=8),
        jump_back_in=[],
        quick_picks=[_to_item(r) for r in _daily_pick(rows, 8, "quick-picks")],
        trending_now=[],
        new_releases=[],
        news=[],
    )


@router.get("/explore_feed", response_model=ExploreFeedResponse)
async def get_explore_feed(db: AsyncSession = Depends(get_db)) -> ExploreFeedResponse:
    rows = await _eligible(db)
    counts = Counter(tag for row in rows for tag in _split_tags(row.tags_text))
    return ExploreFeedResponse(
        trending_events=[],
        personalized_mixes=[],
        categories=[tag.title() for tag, _ in counts.most_common(8)],
    )


@router.get("/search", response_model=list[PlaylistItem])
async def search_music(
    query: str = Query("", max_length=100),
    search_type: str = Query("all"),
    db: AsyncSession = Depends(get_db),
) -> list[PlaylistItem]:
    terms = query.lower().split()[:6]
    if not terms:
        return []
    if search_type == "playlists":
        wanted = " ".join(terms)
        collections = _tag_collections(await _eligible(db), max_cards=50)
        return [c for c in collections if wanted in c.title.lower()][:20]
    stmt = (
        select(CatalogTrackIndex)
        .where(CatalogTrackIndex.session_eligible.is_(True))
        .where(CatalogTrackIndex.audio_url.is_not(None))
    )
    for term in terms:
        stmt = stmt.where(
            CatalogTrackIndex.search_text.like(f"%{_escape_like(term)}%", escape="\\")
        )
    result = await db.execute(stmt.order_by(CatalogTrackIndex.track_id).limit(20))
    return [_to_item(row) for row in result.scalars()]
