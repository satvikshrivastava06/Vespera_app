import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get player => _audioPlayer;

  /// Fetches and plays the 30-second iTunes preview for [title] by [artist].
  /// Throws if no preview is available so the UI can surface a real error state.
  Future<void> playPreview(String title, String artist) async {
    final query = Uri.encodeComponent('$title $artist');
    final url = Uri.parse(
      'https://itunes.apple.com/search?term=$query&media=music&entity=song&limit=1',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('iTunes lookup failed (HTTP ${response.statusCode})');
    }
    final results = (json.decode(response.body)['results'] as List?) ?? [];
    if (results.isEmpty) throw Exception('No preview found for "$title"');
    final previewUrl = results.first['previewUrl'] as String?;
    if (previewUrl == null) throw Exception('Track "$title" has no preview URL');
    await _audioPlayer.setUrl(previewUrl);
    _audioPlayer.play();
  }

  /// Opens the track in the Spotify app; falls back to the web player.
  Future<void> openInSpotify(String spotifyTrackId) async {
    final appUri = Uri.parse('spotify:track:$spotifyTrackId');
    final webUri =
        Uri.parse('https://open.spotify.com/track/$spotifyTrackId');
    if (!await launchUrl(appUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens the track in YouTube Music.
  Future<void> openInYouTubeMusic(String videoId) async {
    final uri = Uri.parse('https://music.youtube.com/watch?v=$videoId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
