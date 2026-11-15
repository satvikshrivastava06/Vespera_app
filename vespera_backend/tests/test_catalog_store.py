from datetime import date, datetime, timezone
from pathlib import Path

from app.catalog.store import load_catalog, save_catalog, to_response
from app.providers.jamendo import JamendoAdapter
from app.schemas.catalog import CatalogFile
from tests.test_jamendo import BY_NC_SA, CONFIRMED


def test_catalog_roundtrip(tmp_path: Path):
    adapter = JamendoAdapter("id", terms_confirmed_on=CONFIRMED)
    track = adapter.to_catalog_track(BY_NC_SA, rights_record_id=1)
    assert track is not None
    path = tmp_path / "catalog.json"
    save_catalog(
        CatalogFile(
            generated_at=datetime.now(timezone.utc),
            policy_version="m1-jamendo-v1",
            tracks=[track],
        ),
        path=path,
    )
    loaded = load_catalog(path)
    assert len(loaded.tracks) == 1
    body = to_response(loaded.tracks[0])
    assert body.session_eligible is True
    assert body.audio_url
    assert body.id == "jamendo:42"
