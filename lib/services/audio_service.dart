import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class AudioPlayerService {
  // Singleton pattern so the music plays globally across all screens
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  String? currentTitle;

  Future<void> playSong(String audioId, String title) async {
    if (audioId.isEmpty) {
      debugPrint("Empty audioId for title: $title");
      return;
    }
    try {
      debugPrint("Starting extraction for ID: $audioId ($title)");
      currentTitle = title;
      
      var manifest = await _yt.videos.streamsClient.getManifest(audioId);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      await _player.setUrl(audioStreamInfo.url.toString());
      _player.play();
      debugPrint("Now Playing: $title");
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playFromSearch(String searchQuery, String title) async {
    if (searchQuery.isEmpty) {
      debugPrint("Empty searchQuery for title: $title");
      return;
    }
    try {
      debugPrint("Searching YouTube for: $searchQuery");
      currentTitle = title;
      
      // 1. Silently search YouTube using the query
      var searchResults = await _yt.search.search(searchQuery);
      
      if (searchResults.isEmpty) {
        debugPrint("No audio found for this track.");
        return;
      }

      // 2. Grab the very first video result
      var video = searchResults.first;
      debugPrint("Found: ${video.title} (${video.url})");

      // 3. Extract the high-quality audio stream from that video
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      
      // 4. Play it!
      await _player.setUrl(audioStreamInfo.url.toString());
      _player.play();
      debugPrint("Now Playing via Search: $title");
      
    } catch (e) {
      debugPrint("Error playing audio via search: $e");
    }
  }

  // Helper functions for the UI
  void pause() => _player.pause();
  void resume() => _player.play();
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  void dispose() {
    _player.dispose();
    _yt.close();
  }
}
