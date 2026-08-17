import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:vespera/models/home_feed.dart';

class ApiService {
  // Set at build time with:
  //   flutter run --dart-define=VESPERA_API_BASE_URL=https://your-backend.example.com/api/v1
  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Opens a Spotify track in the Spotify app, falling back to the web player.
  static Future<void> openInSpotify(String spotifyTrackId) async {
    final appUri = Uri.parse('spotify:track:$spotifyTrackId');
    final webUri =
        Uri.parse('https://open.spotify.com/track/$spotifyTrackId');
    if (!await launchUrl(appUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens a YouTube Music track by video ID.
  static Future<void> openInYouTubeMusic(String videoId) async {
    final uri = Uri.parse('https://music.youtube.com/watch?v=$videoId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<HomeFeedResponse> fetchHomeFeed({
    String localTime = '',
    String weather = 'Clear',
    String location = 'Jabalpur, India',
    int activityBpm = 70,
  }) async {
    final url = Uri.parse('$_baseUrl/home_feed');
    
    try {
      final response = await http.get(url, headers: {
        'local-time': localTime.isEmpty ? DateTime.now().toIso8601String() : localTime,
        'weather': weather,
        'location': location,
        'activity-bpm': activityBpm.toString(),
      });

      if (response.statusCode == 200) {
        return HomeFeedResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load home feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching home feed: $e');
      return _getFallbackData();
    }
  }

  Future<ExploreFeedResponse> fetchExploreFeed() async {
    final url = Uri.parse('$_baseUrl/explore_feed');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return ExploreFeedResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load explore feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching explore feed: $e');
      // High-fidelity local fallback
      return ExploreFeedResponse(
        trendingEvents: [],
        personalizedMixes: [],
        categories: ['All', 'Rock', 'Hip-Hop', 'Pop', 'Jazz'],
      );
    }
  }

  Future<List<PlaylistItem>> search(String query, {String type = "all"}) async {
    final url = Uri.parse('$_baseUrl/search?query=${Uri.encodeComponent(query)}&search_type=$type');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlaylistItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching: $e');
      return [];
    }
  }

  HomeFeedResponse _getFallbackData() {
    return HomeFeedResponse(
      greeting: "Welcome to Vespera",
      aiMessage: "Curating your personal soundscape...",
      rankings: [], // No leaderboard system exists yet — hide rather than fabricate
      popularPlaylists: [
        PlaylistItem(title: "Neon Nights", subtitle: "Cyberpunk Vibe", imageUrl: "https://images.unsplash.com/photo-1550684848-fac1c5b4e853", audioId: "tV_vIdS5X-M", searchQuery: "Cyberpunk music mix"),
        PlaylistItem(title: "Classic Mood", subtitle: "Curated for you", imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea", audioId: "jfKfPfyJRdk", searchQuery: "Classic jazz mix"),
      ],
      jumpBackIn: [
        PlaylistItem(title: "Deep House", subtitle: "Trending", imageUrl: "https://images.unsplash.com/photo-1557672172-298e090bd0f1", audioId: "L_XJ_sCD7GV", searchQuery: "Deep house 2026"),
        PlaylistItem(title: "Twilight Audio", subtitle: "Spatial Mix", imageUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401", audioId: "tV_vIdS5X-M", searchQuery: "Twilight cinematic music"),
      ],
      quickPicks: [],
      trendingNow: [],
      newReleases: [],
      news: [],
    );
  }
}
