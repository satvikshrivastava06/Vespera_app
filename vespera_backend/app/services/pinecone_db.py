import requests
from pinecone import Pinecone
from app.config import settings

# Initialize Pinecone
try:
    pc = Pinecone(api_key=settings.PINECONE_API_KEY)
except Exception:
    pc = None

def get_huggingface_embedding(text: str) -> list:
    """
    Uses HuggingFace's free inference API to convert text to vectors.
    """
    model_id = "sentence-transformers/all-MiniLM-L6-v2"
    api_url = f"https://api-inference.huggingface.co/pipeline/feature-extraction/{model_id}"
    headers = {"Authorization": f"Bearer {settings.HF_TOKEN}"}
    
    try:
        response = requests.post(api_url, headers=headers, json={"inputs": [text]})
        if response.status_code == 200:
            return response.json()[0]
    except Exception:
        pass
    return [0.0] * 384 # Fallback empty vector

def search_music(query: str, target_bpm: int, limit: int = 4):
    """
    Searches Pinecone Vector DB for songs matching the AI's vibe.
    """
    if not pc:
        return _mock_data(query)

    try:
        index = pc.Index(settings.PINECONE_INDEX_NAME)
        query_vector = get_huggingface_embedding(query)
        
        results = index.query(
            vector=query_vector,
            top_k=limit,
            include_metadata=True,
            filter={"bpm": {"$gte": target_bpm - 10, "$lte": target_bpm + 10}} if target_bpm > 100 else None
        )
        
        playlists = []
        for match in results['matches']:
            meta = match['metadata']
            playlists.append({
                "title": meta.get("title", "Unknown Track"),
                "subtitle": f"{meta.get('genre', 'Vibe')} • {meta.get('bpm', '')} BPM",
                "image_url": meta.get("image_url", "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe")
            })
        return playlists

    except Exception as e:
        print(f"Pinecone Error/Empty DB: {e}")
        return _mock_data(query)

def _mock_data(vibe: str):
    return [
        {"title": "Neon Nights", "subtitle": vibe, "image_url": "https://images.unsplash.com/photo-1550684848-fac1c5b4e853"},
        {"title": "Classic Mood", "subtitle": "Curated for you", "image_url": "https://images.unsplash.com/photo-1459749411175-04bf5292ceea"},
        {"title": "Deep House", "subtitle": "Trending", "image_url": "https://images.unsplash.com/photo-1557672172-298e090bd0f1"},
        {"title": "Twilight Audio", "subtitle": "Spatial Mix", "image_url": "https://images.unsplash.com/photo-1534447677768-be436bb09401"}
    ]
