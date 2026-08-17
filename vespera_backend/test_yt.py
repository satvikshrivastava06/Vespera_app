import asyncio
from youtubesearchpython.__future__ import VideosSearch

async def test():
    try:
        videos_search = VideosSearch("test", limit=1)
        results = await videos_search.next()
        print(results)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test())
