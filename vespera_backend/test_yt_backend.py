from ytmusicapi import YTMusic

try:
    yt = YTMusic()
    print("Searching for 'Top Hits'...")
    results = yt.search("Top Hits", filter="songs", limit=5)
    print(f"Songs found: {len(results)}")
    for r in results:
        print(f"- {r['title']} by {r['artists'][0]['name']}")
    
    print("\nSearching for 'Pop' playlists...")
    results = yt.search("Pop", filter="playlists", limit=5)
    print(f"Playlists found: {len(results)}")
    for r in results:
        print(f"- {r['title']}")

    print("\nGetting charts...")
    try:
        charts = yt.get_charts(country='US')
        print(f"Charts found. Songs count: {len(charts.get('songs', {}).get('items', []))}")
    except Exception as e:
        print(f"Charts failed: {e}")

except Exception as e:
    print(f"Error: {e}")
