import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

/// Global singleton audio service used across all screens.
/// Plays 30-second iTunes previews (discovery model — no YouTube stream extraction).
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  String? currentTitle;

  /// Fetches and plays the iTunes 30-second preview for the given [title].
  /// [audioId] is kept in the signature for API compatibility but is unused —
  /// preview is resolved via iTunes Search instead of YouTube stream extraction.
  Future<void> playSong(String audioId, String title) async {
    if (title.isEmpty) {
      debugPrint('AudioPlayerService: empty title — skipping');
      return;
    }
    await _playiTunesPreview(title, '');
  }

  /// Plays a 30-second iTunes preview resolved from [searchQuery].
  /// [searchQuery] should be "Title Artist audio" format from the backend.
  Future<void> playFromSearch(String searchQuery, String title) async {
    if (searchQuery.isEmpty) {
      debugPrint('AudioPlayerService: empty searchQuery for "$title" — skipping');
      return;
    }
    // Strip the trailing " audio" suffix if present, since iTunes handles that
    final cleanQuery = searchQuery.replaceAll(RegExp(r'\s+audio$', caseSensitive: false), '').trim();
    await _playiTunesPreview(cleanQuery, '');
  }

  Future<void> _playiTunesPreview(String term, String artist) async {
    final query = Uri.encodeComponent(artist.isNotEmpty ? '$term $artist' : term);
    final url = Uri.parse(
      'https://itunes.apple.com/search?term=$query&media=music&entity=song&limit=1',
    );
    try {
      currentTitle = term;
      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint('AudioPlayerService: iTunes lookup failed HTTP ${response.statusCode}');
        return;
      }
      final results = (json.decode(response.body)['results'] as List?) ?? [];
      if (results.isEmpty) {
        debugPrint('AudioPlayerService: no iTunes results for "$term"');
        return;
      }
      final previewUrl = results.first['previewUrl'] as String?;
      if (previewUrl == null) {
        debugPrint('AudioPlayerService: no previewUrl for "$term"');
        return;
      }
      await _player.setUrl(previewUrl);
      _player.play();
      debugPrint('AudioPlayerService: playing 30s preview for "$term"');
    } catch (e) {
      debugPrint('AudioPlayerService: error fetching preview for "$term": $e');
    }
  }

  // ── Deep-link hand-offs ──────────────────────────────────────────────────

  /// Opens the track in Spotify (app → web fallback).
  Future<void> openInSpotify(String spotifyTrackId) async {
    final appUri = Uri.parse('spotify:track:$spotifyTrackId');
    final webUri = Uri.parse('https://open.spotify.com/track/$spotifyTrackId');
    if (!await launchUrl(appUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens the track in YouTube Music.
  Future<void> openInYouTubeMusic(String videoId) async {
    final uri = Uri.parse('https://music.youtube.com/watch?v=$videoId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Playback helpers ─────────────────────────────────────────────────────

  void pause() => _player.pause();
  void resume() => _player.play();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}
