from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.schemas.track import PlaybackMode, ProviderTrack

NOW = datetime.now(timezone.utc)


def _full(**overrides):
    data = dict(
        provider="jamendo",
        provider_track_id="1",
        playback_mode=PlaybackMode.FULL_LICENSED,
        audio_url="https://example.com/stream.mp3",
        playable_ms=180_000,
        session_eligible=True,
        rights_record_id=1,
        license="https://creativecommons.org/licenses/by-nc-sa/3.0/",
        verified_at=NOW,
    )
    data.update(overrides)
    return ProviderTrack(**data)


def test_full_licensed_eligible_ok():
    track = _full()
    assert track.session_eligible is True
    assert track.playable_ms == 180_000


def test_full_licensed_requires_rights_record_id():
    with pytest.raises(ValidationError):
        _full(rights_record_id=None)


def test_full_licensed_eligible_requires_positive_playable_ms():
    with pytest.raises(ValidationError):
        _full(playable_ms=0)


def test_preview_allows_zero_playable_ms():
    track = ProviderTrack(
        provider="apple",
        provider_track_id="itunes-1",
        playback_mode=PlaybackMode.PREVIEW,
        preview_asset_ms=30_000,
        playable_ms=0,
        session_eligible=False,
        verified_at=NOW,
    )
    assert track.playable_ms == 0
    assert track.session_eligible is False


def test_preview_rejects_session_playable_ms():
    with pytest.raises(ValidationError):
        ProviderTrack(
            provider="apple",
            provider_track_id="itunes-1",
            playback_mode=PlaybackMode.PREVIEW,
            preview_asset_ms=30_000,
            playable_ms=30_000,
            session_eligible=False,
            verified_at=NOW,
        )


def test_handoff_requires_deep_link_and_zero_playable():
    track = ProviderTrack(
        provider="jamendo",
        provider_track_id="1",
        playback_mode=PlaybackMode.HANDOFF,
        deep_link="https://www.jamendo.com/track/1",
        playable_ms=0,
        session_eligible=False,
        verified_at=NOW,
    )
    assert track.deep_link is not None
    with pytest.raises(ValidationError):
        ProviderTrack(
            provider="jamendo",
            provider_track_id="1",
            playback_mode=PlaybackMode.HANDOFF,
            playable_ms=0,
            session_eligible=False,
            verified_at=NOW,
        )
