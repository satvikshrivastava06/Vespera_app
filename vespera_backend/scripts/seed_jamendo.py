"""Seed 50-100 session-eligible Jamendo tracks into data/m1_catalog.json.

Requires:
  JAMENDO_CLIENT_ID
  JAMENDO_TERMS_CONFIRMED_ON=YYYY-MM-DD  (after you read current API terms)
"""

from __future__ import annotations

import os
import sys
from datetime import date, datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.catalog.store import save_catalog  # noqa: E402
from app.domain.rights import POLICY_VERSION  # noqa: E402
from app.providers.jamendo import JamendoAdapter  # noqa: E402
from app.schemas.catalog import CatalogFile  # noqa: E402


def _terms_date() -> date:
    raw = os.environ.get("JAMENDO_TERMS_CONFIRMED_ON")
    if not raw:
        raise SystemExit(
            "Set JAMENDO_TERMS_CONFIRMED_ON=YYYY-MM-DD after confirming Jamendo terms"
        )
    return date.fromisoformat(raw)


def seed(target: int = 80, max_offset: int = 400) -> Path:
    client_id = os.environ.get("JAMENDO_CLIENT_ID")
    if not client_id:
        raise SystemExit("Set JAMENDO_CLIENT_ID from https://devportal.jamendo.com")
    terms = _terms_date()
    adapter = JamendoAdapter(client_id, terms_confirmed_on=terms)
    collected = []
    seen_ids: set[str] = set()
    artist_counts: dict[str, int] = {}
    offset = 0
    rights_id = 1
    try:
        while len(collected) < target and offset <= max_offset:
            batch = adapter.search_tracks(limit=50, offset=offset)
            if not batch:
                break
            for raw in batch:
                track_id = str(raw.get("id") or "")
                if not track_id or track_id in seen_ids:
                    continue
                artist = (raw.get("artist_name") or "").strip()
                if artist_counts.get(artist, 0) >= 2:
                    continue
                entry = adapter.to_catalog_track(raw, rights_id)
                if entry is None:
                    continue
                seen_ids.add(track_id)
                artist_counts[artist] = artist_counts.get(artist, 0) + 1
                collected.append(entry)
                rights_id += 1
                if len(collected) >= target:
                    break
            offset += 50
    finally:
        adapter.close()

    catalog = CatalogFile(
        generated_at=datetime.now(timezone.utc),
        policy_version=POLICY_VERSION,
        tracks=collected,
    )
    path = save_catalog(catalog)
    print(f"Wrote {len(collected)} session-eligible tracks to {path}")
    if collected:
        sample_n = max(1, len(collected) // 10)
        print(f"Spot-check {sample_n} tracks by hand (license + share URL):")
        for track in collected[:sample_n]:
            print(
                f"  {track.id}  {track.artist} — {track.title}  {track.rights.license_code}  {track.rights.attribution_url}"
            )
    if len(collected) < 50:
        print(
            "WARNING: fewer than 50 eligible tracks. Broaden tags or raise max_offset; "
            "do not silently relax session constraints."
        )
    return path


if __name__ == "__main__":
    seed()
