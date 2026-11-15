import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vespera/models/playable_track.dart';

/// Global singleton. Mini player and Now Playing read this; do not dispose it
/// from a screen.
class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        isPlaying = false;
      }
      notifyListeners();
    });
    _player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _queue.length) return;
      _index = index;
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<PlayableTrack> _queue = [];
  int _index = 0;

  bool isPlaying = false;
  bool isLoading = false;
  String? lastError;

  PlayableTrack? get currentTrack =>
      _queue.isEmpty || _index < 0 || _index >= _queue.length
          ? null
          : _queue[_index];

  String? get currentTitle => currentTrack?.title;
  String? get currentArtist => currentTrack?.artist;
  String? get currentSpotifyId => currentTrack?.spotifyTrackId;
  String? get currentYoutubeId => currentTrack?.youtubeVideoId;
  String? get currentImageUrl => currentTrack?.imageUrl;
  List<PlayableTrack> get queue => List.unmodifiable(_queue);
  int get currentIndex => _index;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  List<HandoffLink> get currentHandoffLinks {
    final track = currentTrack;
    if (track == null) return const [];
    final links = <HandoffLink>[];
    final jamendo = track.jamendoShareUrl;
    if (jamendo != null && jamendo.isNotEmpty) {
      final uri = Uri.tryParse(jamendo);
      if (uri != null) {
        links.add(HandoffLink(
          label: 'Listen on Jamendo',
          uri: uri,
          kind: HandoffKind.jamendo,
        ));
      }
    }
    final apple = track.appleMusicUrl;
    if (apple != null && apple.isNotEmpty) {
      final uri = Uri.tryParse(apple);
      if (uri != null) {
        links.add(HandoffLink(
          label: 'Listen on Apple Music',
          uri: uri,
          kind: HandoffKind.apple,
        ));
      }
    }
    final spotifyId = track.spotifyTrackId;
    if (spotifyId != null && spotifyId.isNotEmpty) {
      links.add(HandoffLink(
        label: 'Spotify',
        uri: Uri.parse('https://open.spotify.com/track/$spotifyId'),
        kind: HandoffKind.spotify,
      ));
    }
    final youtubeId = track.youtubeVideoId;
    if (youtubeId != null && youtubeId.isNotEmpty) {
      links.add(HandoffLink(
        label: 'YouTube Music',
        uri: Uri.parse('https://music.youtube.com/watch?v=$youtubeId'),
        kind: HandoffKind.youtube,
      ));
    }
    return links;
  }

  /// Home/Explore still pass titles without a licensed stream URL.
  /// iTunes promotional previews are not session audio (ADR-001).
  Future<bool> playSong(String audioId, String title) {
    return playTrack(
      PlayableTrack(
        id: audioId.isEmpty ? title : audioId,
        title: title,
        sessionEligible: false,
      ),
    );
  }

  Future<bool> playFromSearch(String searchQuery, String title) {
    return playSong(searchQuery, title);
  }

  Future<bool> playTrack(
    PlayableTrack track, {
    List<PlayableTrack>? queue,
  }) async {
    final upcoming = queue ?? [track];
    final start = queue == null
        ? 0
        : upcoming.indexWhere((item) => item.id == track.id);
    return loadQueue(
      upcoming,
      initialIndex: start < 0 ? 0 : start,
    );
  }

  Future<bool> loadQueue(
    List<PlayableTrack> tracks, {
    int initialIndex = 0,
  }) async {
    final eligible = tracks
        .where(
          (t) =>
              t.sessionEligible &&
              t.audioUrl != null &&
              t.audioUrl!.isNotEmpty,
        )
        .toList();
    if (eligible.isEmpty) {
      lastError =
          'No licensed stream for "${tracks.isEmpty ? 'this track' : tracks[initialIndex.clamp(0, tracks.length - 1)].title}"';
      isPlaying = false;
      isLoading = false;
      notifyListeners();
      return false;
    }
    var index = initialIndex.clamp(0, eligible.length - 1);
    if (tracks.length == eligible.length) {
      index = initialIndex.clamp(0, eligible.length - 1);
    } else {
      index = 0;
    }
    try {
      _queue = eligible;
      _index = index;
      lastError = null;
      isLoading = true;
      notifyListeners();
      await _player.setAudioSources(
        eligible.map(_sourceFor).toList(),
        initialIndex: index,
      );
      await _player.play();
      isPlaying = true;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      isPlaying = false;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  AudioSource _sourceFor(PlayableTrack track) {
    return AudioSource.uri(
      Uri.parse(track.audioUrl!),
      tag: MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        artUri: track.artUri,
      ),
    );
  }

  Future<void> pause() async {
    await _player.pause();
    isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    isPlaying = true;
    notifyListeners();
  }

  Future<void> next() async {
    if (_index + 1 >= _queue.length) return;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_index <= 0) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
  }

  Future<void> openInSpotify(String spotifyTrackId) async {
    if (spotifyTrackId.isEmpty) return;
    final appUri = Uri.parse('spotify:track:$spotifyTrackId');
    final webUri = Uri.parse('https://open.spotify.com/track/$spotifyTrackId');
    if (!await launchUrl(appUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openInYouTubeMusic(String videoId) async {
    if (videoId.isEmpty) return;
    await launchUrl(
      Uri.parse('https://music.youtube.com/watch?v=$videoId'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<bool> openExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
