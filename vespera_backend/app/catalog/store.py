from __future__ import annotations

import json
from pathlib import Path

from app.schemas.catalog import CatalogFile, CatalogTrack, CatalogTrackResponse

DEFAULT_PATH = Path(__file__).resolve().parents[2] / "data" / "m1_catalog.json"


def load_catalog(path: Path | None = None) -> CatalogFile:
    catalog_path = path or DEFAULT_PATH
    if not catalog_path.exists():
        return CatalogFile(policy_version="m1-jamendo-v1", tracks=[])
    return CatalogFile.model_validate_json(catalog_path.read_text(encoding="utf-8"))


def save_catalog(catalog: CatalogFile, path: Path | None = None) -> Path:
    catalog_path = path or DEFAULT_PATH
    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    catalog_path.write_text(
        json.dumps(catalog.model_dump(mode="json"), indent=2),
        encoding="utf-8",
    )
    return catalog_path


def to_response(track: CatalogTrack) -> CatalogTrackResponse:
    mapping = track.provider_track
    return CatalogTrackResponse(
        id=track.id,
        title=track.title,
        artist=track.artist,
        image_url=track.image_url,
        audio_url=mapping.audio_url if mapping.session_eligible else None,
        jamendo_share_url=mapping.deep_link,
        playable_ms=mapping.playable_ms if mapping.session_eligible else 0,
        session_eligible=mapping.session_eligible,
        instrumental_label=track.instrumental_label,
        tags=track.tags,
        license=mapping.license,
    )
