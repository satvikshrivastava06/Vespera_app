import asyncio
from youtubesearchpython.__future__ import VideosSearch
from groq import Groq
import os

async def test():
    try:
        # Initialize Groq (but don't necessarily call it)
        client = Groq(api_key=os.environ.get("GROQ_API_KEY", "mock_key_for_testing"))
        
        videos_search = VideosSearch("test", limit=1)
        results = await videos_search.next()
        print(results)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test())
