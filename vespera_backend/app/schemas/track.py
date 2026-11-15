from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, model_validator


class PlaybackMode(str, Enum):
    FULL_LICENSED = "full_licensed"
    PREVIEW = "preview"
    HANDOFF = "handoff"


class ProviderTrack(BaseModel):
    """What Vespera can legally and technically deliver for one provider mapping.

    ``playable_ms`` is session-countable audio only. Promotional clip length lives
    in ``preview_asset_ms`` and is never summed by the planner.
    """

    provider: str
    provider_track_id: str
    playback_mode: PlaybackMode
    audio_url: str | None = None
    deep_link: str | None = None
    playable_ms: int = Field(ge=0)
    preview_asset_ms: int = Field(default=0, ge=0)
    session_eligible: bool = False
    rights_record_id: int | None = Field(default=None, gt=0)
    license: str | None = None
    verified_at: datetime

    @model_validator(mode="after")
    def validate_capability(self):
        mode = self.playback_mode
        if mode is PlaybackMode.FULL_LICENSED:
            if not (self.audio_url and self.license and self.rights_record_id):
                raise ValueError(
                    "FULL_LICENSED requires audio_url, license and rights_record_id"
                )
            if self.session_eligible and self.playable_ms <= 0:
                raise ValueError(
                    "session_eligible FULL_LICENSED requires playable_ms > 0"
                )
        else:
            if self.session_eligible or self.playable_ms != 0:
                raise ValueError(
                    f"{mode.value} must have playable_ms=0 and session_eligible=False"
                )
            if mode is PlaybackMode.PREVIEW and self.preview_asset_ms <= 0:
                raise ValueError("PREVIEW requires preview_asset_ms > 0")
            if mode is PlaybackMode.HANDOFF and not self.deep_link:
                raise ValueError("HANDOFF requires deep_link")
        if not self.session_eligible and self.playable_ms:
            raise ValueError("playable_ms must be 0 unless session_eligible")
        return self


class DataRightsRecord(BaseModel):
    """Persisted rights decision. A string license URL is not a review by itself."""

    id: int | None = Field(default=None, gt=0)
    source: str
    policy_version: str
    license_code: str | None = None
    license_url: str | None = None
    session_eligible: bool
    reasons: tuple[str, ...] = ()
    attribution_url: str | None = None
    cache_offline_allowed: bool = False
    terms_confirmed_on: datetime
    decided_at: datetime
