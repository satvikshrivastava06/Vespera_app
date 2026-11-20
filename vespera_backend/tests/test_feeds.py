import pathlib
from datetime import datetime, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.infrastructure.models  # noqa: F401  (registers tables)
from app.infrastructure.database import Base, get_db
from app.infrastructure.models import CatalogTrackIndex

_engine = create_async_engine("sqlite+aiosqlite:///:memory:", connect_args={"check_same_thread": False})
_Session = async_sessionmaker(_engine, expire_on_commit=False, autoflush=False)


def _row(track_id: str, title: str, artist: str, tags: list[str], eligible: bool = True) -> CatalogTrackIndex:
    return CatalogTrackIndex(
        track_id=track_id,
        title=title,
        artist=artist,
        image_url=f"https://img.example/{track_id}.jpg",
        audio_url=f"https://audio.example/{track_id}.mp3" if eligible else None,
        jamendo_share_url=f"https://www.jamendo.com/track/{track_id}",
        playable_ms=180_000 if eligible else 0,
        session_eligible=eligible,
        instrumental_label="instrumental" if eligible else None,
        license="by",
        tags_text=" ".join(tags),
        search_text=" ".join([title, artist, *tags]).lower(),
        catalog_version="t1",
        indexed_at=datetime.now(timezone.utc),
    )


@pytest_asyncio.fixture
async def session():
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with _Session() as s:
        yield s
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client(session):
    from main import app

    async def _override():
        yield session

    app.dependency_overrides[get_db] = _override
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def seeded(session):
    session.add_all(
        [
            _row("1", "Slow Rain", "Aria", ["ambient", "piano", "calm"]),
            _row("2", "Night Study", "Bram", ["ambient", "piano"]),
            _row("3", "Deep Focus", "Cleo", ["ambient", "calm"]),
            _row("4", "100% Pure_Tone", "Dax", ["drone"]),
            _row("5", "Restricted Track", "Eli", ["ambient", "piano", "calm"], eligible=False),
        ]
    )
    await session.commit()


@pytest.mark.asyncio
async def test_home_feed_only_returns_playable_catalog_tracks(client, seeded):
    body = (await client.get("/api/v1/home_feed", headers={"local-time": "19:30"})).json()
    assert body["greeting"] == "Good evening"
    picks = body["quick_picks"]
    assert {p["audio_id"] for p in picks} == {"1", "2", "3", "4"}
    assert all(p["session_eligible"] and p["audio_url"] for p in picks)
    assert all(p["jamendo_share_url"] for p in picks)


@pytest.mark.asyncio
async def test_home_feed_does_not_invent_sections(client, seeded):
    body = (await client.get("/api/v1/home_feed")).json()
    for key in ("rankings", "jump_back_in", "trending_now", "new_releases", "news"):
        assert body[key] == [], key


@pytest.mark.asyncio
async def test_home_collections_are_tag_groups_with_enough_tracks(client, seeded):
    cards = (await client.get("/api/v1/home_feed")).json()["popular_playlists"]
    titles = {c["title"]: c for c in cards}
    assert titles["Ambient"]["subtitle"] == "3 tracks"       # the ineligible track is excluded
    assert "Drone" not in titles                              # fewer than 3 tracks
    assert titles["Ambient"]["audio_url"].startswith("https://audio.example/")


@pytest.mark.asyncio
async def test_quick_picks_are_stable_between_calls(client, seeded):
    first = (await client.get("/api/v1/home_feed")).json()["quick_picks"]
    second = (await client.get("/api/v1/home_feed")).json()["quick_picks"]
    assert [p["audio_id"] for p in first] == [p["audio_id"] for p in second]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "header,expected",
    [("08:15", "Good morning"), ("2026-11-15T14:00:00", "Good afternoon"),
     ("7:05 PM", "Good evening"), ("9:05 PM", "Good late night"), ("12:30 AM", "Good late night")],
)
async def test_greeting_follows_device_time(client, header, expected):
    body = (await client.get("/api/v1/home_feed", headers={"local-time": header})).json()
    assert body["greeting"] == expected


@pytest.mark.asyncio
async def test_empty_catalog_returns_empty_valid_feeds(client):
    home = (await client.get("/api/v1/home_feed")).json()
    assert home["quick_picks"] == [] and home["popular_playlists"] == []
    assert home["ai_message"] == "No tracks are available yet."
    explore = (await client.get("/api/v1/explore_feed")).json()
    assert explore["categories"] == []
    assert (await client.get("/api/v1/search", params={"query": "rain"})).json() == []


@pytest.mark.asyncio
async def test_explore_categories_come_from_real_tags(client, seeded):
    body = (await client.get("/api/v1/explore_feed")).json()
    assert body["categories"][0] == "Ambient"
    assert body["trending_events"] == [] and body["personalized_mixes"] == []


@pytest.mark.asyncio
async def test_search_matches_all_terms_and_skips_ineligible(client, seeded):
    hits = (await client.get("/api/v1/search", params={"query": "ambient piano"})).json()
    assert {h["audio_id"] for h in hits} == {"1", "2"}
    assert (await client.get("/api/v1/search", params={"query": "restricted"})).json() == []


@pytest.mark.asyncio
async def test_search_treats_like_wildcards_literally(client, seeded):
    assert (await client.get("/api/v1/search", params={"query": "%"})).json() != []  # literal % exists in a title
    assert (await client.get("/api/v1/search", params={"query": "zzz%"})).json() == []
    assert [h["audio_id"] for h in (await client.get("/api/v1/search", params={"query": "pure_tone"})).json()] == ["4"]
    assert (await client.get("/api/v1/search", params={"query": "pure_xone"})).json() == []


@pytest.mark.asyncio
async def test_search_blank_query_and_playlist_mode(client, seeded):
    assert (await client.get("/api/v1/search", params={"query": "   "})).json() == []
    cards = (await client.get("/api/v1/search", params={"query": "amb", "search_type": "playlists"})).json()
    assert [c["title"] for c in cards] == ["Ambient"]


def test_legacy_stack_is_gone():
    app_dir = pathlib.Path(__file__).parent.parent / "app"
    assert not (app_dir / "legacy" / "__init__.py").exists()
    assert not (app_dir / "services" / "pinecone_db.py").exists()
    requirements = (pathlib.Path(__file__).parent.parent / "requirements.txt").read_text().lower()
    for package in ("spotipy", "ytmusicapi", "youtube-search-python", "pinecone"):
        assert package not in requirements
