"""Jamendo tracks adapter. Streams only after decide_rights; no offline cache."""

from __future__ import annotations

from datetime import date, datetime, timezone

import httpx

from app.domain.rights import POLICY_VERSION, decide_rights
from app.infrastructure.http import get_with_backoff
from app.schemas.catalog import CatalogTrack
from app.schemas.track import DataRightsRecord, PlaybackMode, ProviderTrack

JAMENDO_TRACKS_URL = "https://api.jamendo.com/v3.0/tracks/"


def _flatten_tags(tags: object) -> list[str]:
    if isinstance(tags, dict):
        values: list[str] = []
        for key in ("genres", "instruments", "vartags"):
            values.extend(str(item) for item in (tags.get(key) or []))
        return values
    if isinstance(tags, list):
        return [str(item) for item in tags]
    return []



class JamendoAdapter:
    def __init__(
        self,
        client_id: str,
        *,
        client: httpx.Client | None = None,
        terms_confirmed_on: date | None = None,
    ) -> None:
        if not client_id:
            raise ValueError("JAMENDO_CLIENT_ID is required")
        self.client_id = client_id
        self._client = client or httpx.Client()
        self._owns_client = client is None
        self.terms_confirmed_on = terms_confirmed_on

    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def search_tracks(
        self,
        *,
        vocalinstrumental: str = "instrumental",
        fuzzytags: str | None = "relax+calm+study",
        limit: int = 50,
        offset: int = 0,
        groupby: str | None = "artist_id",
        ids: list[str] | None = None,
    ) -> list[dict]:
        params: dict[str, str | int] = {
            "client_id": self.client_id,
            "format": "json",
            "include": "licenses+musicinfo",
            "audioformat": "mp32",
            "limit": min(limit, 200),
            "offset": offset,
        }
        if ids:
            params["id"] = " ".join(ids)
        else:
            params["vocalinstrumental"] = vocalinstrumental
            params["durationbetween"] = "90_360"
            if fuzzytags:
                params["fuzzytags"] = fuzzytags
            if groupby:
                params["groupby"] = groupby
        response = get_with_backoff(self._client, JAMENDO_TRACKS_URL, params=params)
        response.raise_for_status()
        payload = response.json()
        headers = payload.get("headers") or {}
        if headers.get("status") != "success" and headers.get("code") not in (0, "0", None):
            raise RuntimeError(headers.get("error_message") or "Jamendo search failed")
        return list(payload.get("results") or [])

    def to_catalog_track(self, raw: dict, rights_record_id: int) -> CatalogTrack | None:
        if self.terms_confirmed_on is None:
            raise RuntimeError(
                "Set JAMENDO_TERMS_CONFIRMED_ON after confirming current Jamendo terms"
            )
        track_id = str(raw.get("id") or "")
        title = (raw.get("name") or "").strip()
        artist = (raw.get("artist_name") or "").strip()
        audio_url = raw.get("audio") or None
        shareurl = raw.get("shareurl") or None
        license_url = raw.get("license_ccurl") or None
        duration_s = raw.get("duration")
        try:
            duration_s_int = int(duration_s) if duration_s is not None else None
        except (TypeError, ValueError):
            duration_s_int = None
        decision = decide_rights(
            license_url,
            audio_url,
            duration_s_int,
            shareurl,
            terms_confirmed_on=self.terms_confirmed_on,
        )
        if not decision.session_eligible:
            return None

        now = datetime.now(timezone.utc)
        terms_dt = datetime.combine(self.terms_confirmed_on, datetime.min.time(), tzinfo=timezone.utc)
        rights = DataRightsRecord(
            id=rights_record_id,
            source="jamendo",
            policy_version=POLICY_VERSION,
            license_code=decision.license_code,
            license_url=license_url,
            session_eligible=True,
            reasons=decision.reasons,
            attribution_url=shareurl,
            cache_offline_allowed=False,
            terms_confirmed_on=terms_dt,
            decided_at=decision.decided_at,
        )
        provider = ProviderTrack(
            provider="jamendo",
            provider_track_id=track_id,
            playback_mode=PlaybackMode.FULL_LICENSED,
            audio_url=audio_url,
            deep_link=shareurl,
            playable_ms=(duration_s_int or 0) * 1000,
            preview_asset_ms=0,
            session_eligible=True,
            rights_record_id=rights_record_id,
            license=license_url,
            verified_at=now,
        )
        musicinfo = raw.get("musicinfo") or {}
        tags = _flatten_tags(musicinfo.get("tags"))
        vocal = musicinfo.get("vocalinstrumental")
        return CatalogTrack(
            id=f"jamendo:{track_id}",
            title=title or f"Jamendo {track_id}",
            artist=artist,
            image_url=raw.get("image") or None,
            tags=tags,
            instrumental_label="labelled instrumental by Jamendo"
            if vocal == "instrumental"
            else None,
            duration_ms=(duration_s_int or 0) * 1000,
            provider_track=provider,
            rights=rights,
        )
