from fastapi import FastAPI, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
from groq import Groq
from youtubesearchpython.__future__ import VideosSearch # Async open-source YouTube fetcher
import asyncio
import os
import datetime
import time
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials

# Optional: YTMusic API for better real-world data
try:
    from ytmusicapi import YTMusic
    yt_music = YTMusic()
except ImportError:
    yt_music = None
    print("WARNING: ytmusicapi not installed. Using basic YouTube search fallback.")


app = FastAPI(title="Vespera AI Backend (Spotify Premium UI)")

# Allow Flutter app to communicate with backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Initialize Spotify API ---
# Load from .env if exists
from dotenv import load_dotenv
load_dotenv()

def get_spotify_client():
    client_id = os.environ.get("SPOTIPY_CLIENT_ID")
    client_secret = os.environ.get("SPOTIPY_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("WARNING: Spotify credentials missing. Using high-fidelity fallback mode.")
        return None
    try:
        return spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials(
            client_id=client_id,
            client_secret=client_secret
        ))
    except Exception:
        return None

spotify = get_spotify_client()
groq_client = Groq(api_key=os.environ.get("GROQ_API_KEY", "mock_key"))

def get_ai_recommendations(time_context: str, weather: str, location: str):
    """
    RAG & LLM Logic:
    Analyses user context (Time, Weather, Location) using Deep Learning patterns.
    """
    prompt = f"Analyze context (Time: {time_context}, Weather: {weather}) for Vespera. Output MESSAGE: [concise status] and CATEGORIES: [comma separated Spotify categories like 'pop,chill']."
    try:
        completion = groq_client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama3-8b-8192",
        )
        resp = completion.choices[0].message.content
        msg = resp.split("MESSAGE:")[1].split("CATEGORIES:")[0].strip()
        cats = resp.split("CATEGORIES:")[1].strip().split(",")
        return msg, [c.strip() for c in cats]
    except:
        return "Deep Sync: Optimizing atmospheric audio frequencies.", ["pop", "chill"]

# --- Pydantic Data Models ---
class PlaylistItem(BaseModel):
    title: str
    subtitle: str
    image_url: str
    search_query: str # NEW: We pass this to Flutter to find the audio on YouTube!
    audio_id: Optional[str] = None

class UserRanking(BaseModel):
    name: str
    rank: int
    image_url: str

class NewsItem(BaseModel):
    category: str
    title: str
    subtitle: str
    image_url: str

class ExploreFeedResponse(BaseModel):
    trending_events: List[PlaylistItem]
    personalized_mixes: List[PlaylistItem]
    categories: List[str]

class HomeFeedResponse(BaseModel):
    greeting: str
    ai_message: Optional[str] = ""
    rankings: List[UserRanking]
    popular_playlists: List[PlaylistItem]
    jump_back_in: List[PlaylistItem]
    quick_picks: List[PlaylistItem]
    trending_now: List[PlaylistItem]
    new_releases: List[PlaylistItem]
    news: List[NewsItem]

# --- Dynamic YouTube/YTMusic Fallback Logic ---
async def fetch_real_world_music(query: str, limit: int = 5, use_charts: bool = False, search_filter: Optional[str] = "songs") -> List[PlaylistItem]:
    """Fetches real-world music data from YTMusic (preferred) or YouTube."""
    items = []
    
    # Try YTMusic first for higher quality music metadata
    if yt_music:
        try:
            print(f"--- Fetching YTMusic Data ({search_filter}): {query} ---")
            if use_charts:
                # Use a specific country for charts if ZZ fails
                try:
                    charts = yt_music.get_charts(country='US')
                except:
                    charts = yt_music.get_charts()
                
                results = charts.get('songs', {}).get('items', [])[:limit]
                for v in results:
                    artist_name = v['artists'][0]['name'] if v.get('artists') else "Artist"
                    items.append(PlaylistItem(
                        title=v.get('title', 'Unknown Track'),
                        subtitle=artist_name,
                        image_url=v['thumbnails'][-1]['url'] if v.get('thumbnails') else "https://images.unsplash.com/photo-1614680376593-902f74cf0d41",
                        search_query=f"{v.get('title', 'Track')} {artist_name} audio",
                        audio_id=v.get('videoId', '')
                    ))
                if items: return items
            else:
                # Map our filter to YTMusic filters
                yt_filter = "playlists" if search_filter == "playlists" else "songs"
                results = yt_music.search(query, filter=yt_filter, limit=limit)
                for v in results:
                    if yt_filter == "playlists":
                        img = v['thumbnails'][-1]['url'] if v.get('thumbnails') else "https://images.unsplash.com/photo-1614680376593-902f74cf0d41"
                        items.append(PlaylistItem(
                            title=v.get('title', 'Popular Playlist'),
                            subtitle=f"{v.get('itemCount', 'Many')} songs",
                            image_url=img,
                            search_query=f"{v.get('title', 'Playlist')} full playlist",
                            audio_id=v.get('browseId', '')
                        ))
                    else:
                        artists_str = v['artists'][0]['name'] if v.get('artists') else "Artist"
                        img = v['thumbnails'][-1]['url'] if v.get('thumbnails') else "https://images.unsplash.com/photo-1614680376593-902f74cf0d41"
                        items.append(PlaylistItem(
                            title=v.get('title', 'Unknown Title'),
                            subtitle=artists_str,
                            image_url=img,
                            search_query=f"{v.get('title', 'Track')} {artists_str} audio",
                            audio_id=v.get('videoId', '')
                        ))
                if items: return items
        except Exception as e:
            print(f"YTMusic Error for query '{query}': {e}")

    # Fallback to general YouTube Search
    print(f"--- Falling back to YouTube Search: {query} ---")
    try:
        from youtubesearchpython.__future__ import VideosSearch
        search = VideosSearch(query, limit=limit)
        result = await search.next()
        for v in result.get('result', []):
            try:
                thumb = v.get('thumbnails', [{}])[0].get('url', "https://images.unsplash.com/photo-1614680376593-902f74cf0d41")
                title = v.get('title', 'Unknown Video')
                title_clean = str(title)[:40] if title else "Unknown Track"
                channel = v.get('channel', {}).get('name', "Artist")
                items.append(PlaylistItem(
                    title=title_clean, 
                    subtitle=channel if channel else "Artist", 
                    image_url=thumb, 
                    search_query=f"{title_clean} audio",
                    audio_id=v.get('id', '')
                ))
            except Exception:
                continue
        return items
    except Exception as e:
        print(f"YouTube Search Error for query '{query}': {e}")
        return []


# --- Spotify Fetching Logic (Async) ---
async def fetch_spotify_category(category_id: str, limit: int = 5, is_playlist: bool = False) -> List[PlaylistItem]:
    """Fetches official playlists from a Spotify category."""
    if spotify is None:
        if category_id == "toplists":
            query = "Top Global Playlists 2026"
        else:
            query = f"Popular {category_id} playlists 2026" if is_playlist else f"Top {category_id} hits 2026"
        search_filter = "playlists" if is_playlist else "songs"
        return await fetch_real_world_music(query, limit, search_filter=search_filter)
    try:
        loop = asyncio.get_event_loop()
        results = await loop.run_in_executor(None, lambda: spotify.category_playlists(category_id=category_id, limit=limit))
        return [PlaylistItem(title=p['name'], subtitle=p['description'][:40] + "...", image_url=p['images'][0]['url'], search_query=f"{p['name']} playlist") for p in results['playlists']['items']]
    except Exception as e:
        print(f"Spotify Category Error ({category_id}): {e}")
        query = f"Trending {category_id} Playlists" if is_playlist else f"Popular {category_id} music"
        return await fetch_real_world_music(query, limit, search_filter="playlists" if is_playlist else "songs")


async def fetch_spotify_tracks(playlist_id: str, limit: int = 5) -> List[PlaylistItem]:
    """Fetches tracks from a Spotify playlist."""
    if spotify is None:
        is_charts = "ZEVXbM" in playlist_id or "cBWIGoY" in playlist_id
        query = "Global Top 50 Hits 2026" if is_charts else "Trending Pop Music"
        return await fetch_real_world_music(query, limit, use_charts=is_charts)
    try:
        loop = asyncio.get_event_loop()
        results = await loop.run_in_executor(None, lambda: spotify.playlist_tracks(playlist_id, limit=limit))
        items = []
        for item in results.get('items', []):
            track = item.get('track')
            if not track: continue
            artist_name = track['artists'][0]['name'] if track.get('artists') else "Artist"
            items.append(PlaylistItem(title=track['name'], subtitle=artist_name, image_url=track['album']['images'][0]['url'], search_query=f"{track['name']} {artist_name} audio"))
        return items
    except Exception as e:
        print(f"Spotify Tracks Error ({playlist_id}): {e}")
        return await fetch_real_world_music("Top Billboard Hits 2026", limit)

async def fetch_spotify_new_releases(limit: int = 5) -> List[PlaylistItem]:
    """Fetches new releases."""
    if spotify is None:
        return await fetch_real_world_music("New Music Friday Releases 2026", limit)
    try:
        loop = asyncio.get_event_loop()
        results = await loop.run_in_executor(None, lambda: spotify.new_releases(limit=limit))
        return [PlaylistItem(title=album['name'], subtitle=album['artists'][0]['name'], image_url=album['images'][0]['url'], search_query=f"{album['name']} {album['artists'][0]['name']} audio") for album in results['albums']['items']]
    except Exception as e:
        print(f"Spotify New Releases Error: {e}")
        return await fetch_real_world_music("Fresh new music releases", limit)


@app.get("/api/v1/home_feed", response_model=HomeFeedResponse)
async def get_home_feed(
    local_time: Optional[str] = Header(None), 
    weather: Optional[str] = Header(None)
):
    current_hour = datetime.datetime.now().hour
    time_context = "morning" if 5 <= current_hour < 12 else "afternoon" if 12 <= current_hour < 17 else "evening" if 17 <= current_hour < 21 else "late night"
    greeting = f"Good {time_context}"

    # --- AI Contextual Recommendation ---
    weather_val = weather if weather else "Clear"
    ai_status, suggested_cats = "Calibrating your rhythmic atmosphere...", ["pop", "chill"]
    try:
        ai_status, suggested_cats = get_ai_recommendations(time_context, weather_val, "Global")
    except: pass

    # --- Concurrent Fetching for Performance ---
    # Ensure suggested_cats has at least 2 categories
    if len(suggested_cats) < 2: suggested_cats = ["pop", "chill"]
    
    tasks = [
        fetch_spotify_category(suggested_cats[0], limit=8, is_playlist=True), # Popular Playlists
        fetch_spotify_tracks("37i9dQZF1DX4WYpdVIPcmO", limit=8), # Jump back in
        fetch_spotify_category(suggested_cats[1], limit=8), # Quick picks
        fetch_spotify_tracks("37i9dQZEVXbMDoHDwVN2tF", limit=8), # Trending Now
        fetch_spotify_new_releases(limit=8), # New Releases
    ]
    
    raw_results = await asyncio.gather(*tasks, return_exceptions=True)
    results = [res if not isinstance(res, Exception) else [] for res in raw_results]

    return HomeFeedResponse(
        greeting=greeting,
        ai_message=ai_status,
        rankings=[
            UserRanking(name="Luna Ray", rank=1, image_url="https://api.dicebear.com/7.x/avataaars/svg?seed=Luna"),
            UserRanking(name="M. Davis", rank=2, image_url="https://api.dicebear.com/7.x/avataaars/svg?seed=Davis"),
            UserRanking(name="Synth Kid", rank=3, image_url="https://api.dicebear.com/7.x/avataaars/svg?seed=Kid"),
        ],
        popular_playlists=results[0],
        jump_back_in=results[1],
        quick_picks=results[2],
        trending_now=results[3],
        new_releases=results[4],
        news=[
            NewsItem(category="TRENDING", title="Global Hits 2026", subtitle="The sound of the future is here.", image_url="https://images.unsplash.com/photo-1459749411175-04bf5292ceea"),
            NewsItem(category="EXCLUSIVE", title="Vespera Spatial Audio", subtitle="Experience music like never before.", image_url="https://images.unsplash.com/photo-1598488035139-bdbb2231ce04"),
        ]
    )


@app.get("/api/v1/explore_feed", response_model=ExploreFeedResponse)
async def get_explore_feed():
    # Concurrent Fetching for Explore with actual playlists and trending data
    raw_results = await asyncio.gather(
        fetch_spotify_category("toplists", limit=10, is_playlist=True), # Trending Playlists
        fetch_spotify_tracks("37i9dQZEVXbMDoHDwVN2tF", limit=12), # Global Top 50 Songs
        return_exceptions=True
    )
    results = [res if not isinstance(res, Exception) else [] for res in raw_results]
    
    return ExploreFeedResponse(
        trending_events=results[0],
        personalized_mixes=results[1],
        categories=["Hyperpop", "Chill", "Lofi", "Techno", "Classical", "Indie"]
    )


@app.get("/api/v1/search", response_model=List[PlaylistItem])
async def search_music(query: str, search_type: str = "all"):
    """
    Search for music (songs, playlists) using YTMusic API.
    search_type can be 'all', 'songs', or 'playlists'.
    """
    try:
        # If query is empty, return empty list
        if not query or len(query.strip()) < 1:
            return []

        results = []
        
        # Filter logic
        yt_filter = "playlists" if search_type == "playlists" else "songs"
            
        # Perform search
        # We run this in a thread to keep FastAPI async loop responsive
        if not yt_music:
            # Fallback to general YouTube Search
            from youtube_search_python import VideosSearch
            search = VideosSearch(query, limit=10)
            yt_results = search.result().get("result", [])
            for item in yt_results:
                results.append(PlaylistItem(
                    title=item.get("title", "Unknown"),
                    subtitle=item.get("channel", {}).get("name") if item.get("channel") else "YouTube",
                    image_url=item.get("thumbnails")[0].get("url") if item.get("thumbnails") else "",
                    search_query=f"{item.get('title')} audio",
                    audio_id=item.get("id")
                ))
            return results

        raw_results = await asyncio.to_thread(yt_music.search, query, filter=yt_filter, limit=20)
        
        for item in raw_results:
            try:
                # Extract image
                thumbnails = item.get("thumbnails", [])
                image_url = thumbnails[-1]["url"] if thumbnails else "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500"
                
                # Extract artist/subtitle
                artists = item.get("artists", [])
                subtitle = artists[0].get("name", "Unknown Artist") if artists else "Unknown Artist"
                if "album" in item and item["album"]:
                    subtitle += f" • {item['album'].get('name', '')}"
                elif "author" in item:
                    subtitle = item.get("author", "Vespera Artist")
                
                results.append(PlaylistItem(
                    title=item.get("title", "Unknown"),
                    subtitle=subtitle,
                    image_url=image_url,
                    search_query=f"{item.get('title')} {subtitle} audio",
                    audio_id=item.get("videoId") or item.get("playlistId")
                ))
            except Exception as e:
                print(f"Error parsing search result: {e}")
                continue
                
        return results
    except Exception as e:
        print(f"Search error: {e}")
        return []


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
