from datetime import date

from app.providers.jamendo import JamendoAdapter

CONFIRMED = date(2026, 11, 15)

BY_NC_SA = {
    "id": "42",
    "name": "Focus Study",
    "artist_name": "Quiet Room",
    "duration": 180,
    "audio": "https://mp3l.jamendo.com/?trackid=42",
    "shareurl": "https://www.jamendo.com/track/42",
    "license_ccurl": "https://creativecommons.org/licenses/by-nc-sa/3.0/",
    "image": "https://example.com/cover.jpg",
    "musicinfo": {
        "vocalinstrumental": "instrumental",
        "tags": {"genres": ["ambient"], "vartags": ["calm"]},
    },
}

BY_NC_ND = {
    **BY_NC_SA,
    "id": "43",
    "license_ccurl": "https://creativecommons.org/licenses/by-nc-nd/3.0/",
}


def test_eligible_jamendo_track_maps_to_full_licensed():
    adapter = JamendoAdapter("test-id", terms_confirmed_on=CONFIRMED)
    track = adapter.to_catalog_track(BY_NC_SA, rights_record_id=1)
    assert track is not None
    assert track.id == "jamendo:42"
    assert track.provider_track.session_eligible is True
    assert track.provider_track.playable_ms == 180_000
    assert track.instrumental_label == "labelled instrumental by Jamendo"
    assert track.rights.cache_offline_allowed is False


def test_nd_license_is_excluded():
    adapter = JamendoAdapter("test-id", terms_confirmed_on=CONFIRMED)
    assert adapter.to_catalog_track(BY_NC_ND, rights_record_id=2) is None


def test_terms_gate():
    adapter = JamendoAdapter("test-id", terms_confirmed_on=None)
    try:
        adapter.to_catalog_track(BY_NC_SA, rights_record_id=1)
    except RuntimeError as exc:
        assert "JAMENDO_TERMS_CONFIRMED_ON" in str(exc)
    else:
        raise AssertionError("expected terms gate")
