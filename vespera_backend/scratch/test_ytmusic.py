from ytmusicapi import YTMusic
import json

try:
    yt = YTMusic()
    results = yt.search("Top Hits", filter="songs", limit=3)
    print(json.dumps(results, indent=2))
except Exception as e:
    print(f"Error: {e}")
