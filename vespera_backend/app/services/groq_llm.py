import json
from groq import Groq
from app.config import settings

# Initialize Groq client
try:
    client = Groq(api_key=settings.GROQ_API_KEY)
except Exception:
    client = None

def generate_contextual_vibe(local_time: str, weather: str, location: str, activity_bpm: int) -> dict:
    """
    Uses the Groq LLM to act as the AI DJ. 
    It analyzes context and returns a JSON payload with a greeting and target music genres.
    """
    prompt = f"""
    You are 'Vespera', an advanced, emotionally intelligent AI Music DJ. 
    Analyze the user's current context:
    - Time: {local_time}
    - Weather: {weather}
    - Location: {location}
    - User Activity: {activity_bpm} BPM (If > 100, they are exercising/running. If < 60, they are resting).

    Based on this, determine the perfect musical vibe.
    Return ONLY a valid JSON object with the following structure:
    {{
        "greeting": "A short, cool UI greeting like 'Late night in Jabalpur' or 'Rainy Morning Focus'",
        "dj_message": "A 1-sentence friendly message explaining why you chose this vibe.",
        "search_query": "3-4 keywords to search in our Vector Database (e.g., 'high energy cyberpunk synthwave', 'lofi acoustic acoustic chuva')",
        "target_bpm": 100
    }}
    """

    if not client:
        return _fallback_vibe()

    try:
        response = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama3-8b-8192",
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
