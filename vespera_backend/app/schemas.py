from pydantic import BaseModel
from typing import List, Optional

class PlaylistItem(BaseModel):
    title: str
    subtitle: str
    image_url: str
    search_query: str = ""
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

class HomeFeedResponse(BaseModel):
    greeting: str
    ai_message: str
    rankings: List[UserRanking]
    popular_playlists: List[PlaylistItem]
    jump_back_in: List[PlaylistItem]
    quick_picks: List[PlaylistItem]
    trending_now: List[PlaylistItem]
    new_releases: List[PlaylistItem]
    news: List[NewsItem]
