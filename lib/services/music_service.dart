import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  AudioPlayer get player => _audioPlayer;

  Future<void> playSong(String searchQuery) async {
    try {
      // 1. Silently search YouTube for the audio
      var searchResults = await _yt.search.search("$searchQuery official audio");
      if (searchResults.isEmpty) return;
      
      var video = searchResults.first;

      // 2. Extract the highest quality audio-only stream
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();

      // 3. Play it in the background!
      await _audioPlayer.setUrl(audioStream.url.toString());
      _audioPlayer.play();
      
      print("Now Playing: ${video.title}");
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _yt.close();
  }
}
