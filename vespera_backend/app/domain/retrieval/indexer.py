"""Catalog indexer — VSP-011.

Reads the JSON catalog file and upserts rows into ``catalog_track_index``.
Called once at startup and whenever the catalog file is reloaded.

Design rules (roadmap Gate 5):
- search_text is the lowercased concatenation of title + artist + tags.
  It is the ONLY text searched during retrieval; no LLM-generated text
  enters the index.
- session_eligible is copied verbatim from the catalog; non-eligible
  tracks are indexed but excluded from retrieval results.
- A catalog_version hash guards against redundant re-indexing on hot-reload.
"""

from __future__ import annotations

import hashlib
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.catalog.store import DEFAULT_PATH, load_catalog
from app.infrastructure.models import CatalogTrackIndex
from app.schemas.catalog import CatalogFile

log = logging.getLogger(__name__)


def _catalog_version(catalog: CatalogFile) -> str:
    """Stable hash of the catalog content used to skip redundant re-indexing."""
    payload = json.dumps(
        [t.id for t in catalog.tracks], sort_keys=True
    ).encode()
    return hashlib.sha256(payload).hexdigest()[:16]


async def index_catalog(db: AsyncSession, path: Path | None = None) -> int:
    """Upsert all catalog tracks into ``catalog_track_index``.

    Returns the number of rows written.  Skips the write if the catalog
    version has not changed since the last index run.
    """
    catalog = load_catalog(path)
    if not catalog.tracks:
        log.info("Catalog is empty — nothing to index.")
        return 0

    version = _catalog_version(catalog)

    # Check whether the current index already matches this version.
    existing = await db.execute(
        select(CatalogTrackIndex.catalog_version).limit(1)
    )
    current_version = existing.scalar_one_or_none()
    if current_version == version:
        log.debug("Catalog index is current (version=%s) — skipping re-index.", version)
        return 0

    # Drop existing index rows and rebuild.
    await db.execute(delete(CatalogTrackIndex))

    now = datetime.now(timezone.utc)
    count = 0
    for track in catalog.tracks:
        pt = track.provider_track
        tags = track.tags or []
        search_text = " ".join(
            filter(None, [track.title, track.artist] + tags)
        ).lower()

        row = CatalogTrackIndex(
            track_id=track.id,
            title=track.title,
            artist=track.artist,
            image_url=track.image_url,
            audio_url=pt.audio_url if pt.session_eligible else None,
            jamendo_share_url=pt.deep_link,
            playable_ms=pt.playable_ms if pt.session_eligible else 0,
            session_eligible=pt.session_eligible,
            instrumental_label=track.instrumental_label,
            license=pt.license,
            tags_text=" ".join(tags),
            search_text=search_text,
            catalog_version=version,
            indexed_at=now,
        )
        db.add(row)
        count += 1

    await db.flush()
    log.info("Catalog indexed: %d tracks (version=%s).", count, version)
    return count
