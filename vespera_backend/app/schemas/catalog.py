from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.track import DataRightsRecord, ProviderTrack


class CatalogTrack(BaseModel):
    """Seeded M1 catalog row: canonical metadata + one provider mapping + rights."""

    id: str
    title: str
    artist: str
    image_url: str | None = None
    tags: list[str] = Field(default_factory=list)
    instrumental_label: str | None = None
    duration_ms: int = Field(ge=0, default=0)
    provider_track: ProviderTrack
    rights: DataRightsRecord


class CatalogFile(BaseModel):
    generated_at: datetime | None = None
    policy_version: str
    tracks: list[CatalogTrack] = Field(default_factory=list)


class CatalogTrackResponse(BaseModel):
    id: str
    title: str
    artist: str
    image_url: str | None = None
    audio_url: str | None = None
    jamendo_share_url: str | None = None
    playable_ms: int
    session_eligible: bool
    instrumental_label: str | None = None
    tags: list[str] = Field(default_factory=list)
    license: str | None = None
