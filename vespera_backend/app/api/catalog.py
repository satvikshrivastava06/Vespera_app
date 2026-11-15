from fastapi import APIRouter, HTTPException

from app.catalog.store import load_catalog, to_response
from app.schemas.catalog import CatalogTrackResponse

router = APIRouter()


@router.get("/health")
def health() -> dict:
    catalog = load_catalog()
    return {
        "status": "ok",
        "catalog_tracks": len(catalog.tracks),
        "session_eligible": sum(
            1 for track in catalog.tracks if track.provider_track.session_eligible
        ),
    }


@router.get("/catalog", response_model=list[CatalogTrackResponse])
def list_catalog(eligible_only: bool = True) -> list[CatalogTrackResponse]:
    catalog = load_catalog()
    tracks = catalog.tracks
    if eligible_only:
        tracks = [t for t in tracks if t.provider_track.session_eligible]
    return [to_response(t) for t in tracks]


@router.get("/catalog/{track_id:path}", response_model=CatalogTrackResponse)
def get_catalog_track(track_id: str) -> CatalogTrackResponse:
    catalog = load_catalog()
    for track in catalog.tracks:
        if track.id == track_id or track.provider_track.provider_track_id == track_id:
            if not track.provider_track.session_eligible:
                raise HTTPException(403, "Track is not session-eligible")
            return to_response(track)
    raise HTTPException(404, "Track not found")
