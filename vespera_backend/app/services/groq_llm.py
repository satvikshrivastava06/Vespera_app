import json
from groq import Groq
from app.config import settings

# Initialize Groq client
try:
    client = Groq(api_key=settings.GROQ_API_KEY)
except Exception:
    client = None

def generate_contextual_vibe(local_time: str, weather: str, location: str = "", activity_bpm: int = 70) -> dict:
    """
    Uses the Groq LLM to act as the AI DJ.
    Location is optional and must not include precise coordinates.
    """
    location_line = f"- Coarse location: {location}\n" if location.strip() else ""
    prompt = f"""
    You are 'Vespera', an advanced, emotionally intelligent AI Music DJ.
    Analyze the user's current context:
    - Time: {local_time}
    - Weather: {weather}
    {location_line}- User Activity: {activity_bpm} BPM (If > 100, they are exercising/running. If < 60, they are resting).

    Based on this, determine the perfect musical vibe.
    Return ONLY a valid JSON object with the following structure:
    {{
        "greeting": "A short UI greeting like 'Rainy Morning Focus'",
        "dj_message": "A 1-sentence friendly message explaining why you chose this vibe.",
        "search_query": "3-4 keywords to search in our Vector Database (e.g., 'high energy cyberpunk synthwave', 'lofi acoustic')",
        "target_bpm": 100
    }}
    Do not invent a city or precise location.
    """

    if not client:
        return _fallback_vibe()

    try:
        response = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model=settings.GROQ_MODEL,
            temperature=0.7,
            response_format={"type": "json_object"} 
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        print(f"LLM Error: {e}")
        return _fallback_vibe()

def _fallback_vibe():
    return {
        "greeting": "Welcome to Vespera",
        "dj_message": "Curating your personal soundscape...",
        "search_query": "popular trending music",
        "target_bpm": 100
    }
