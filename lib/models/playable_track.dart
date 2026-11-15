class PlayableTrack {
  /// Canonical id (Jamendo track id, or another provider id once mapped).
  final String id;
  final String title;
  final String artist;
  final String? audioUrl;
  final String? imageUrl;
  final String? jamendoShareUrl;
  final String? appleMusicUrl;
  final String? spotifyTrackId;
  final String? youtubeVideoId;
  final int playableMs;
  final bool sessionEligible;

  const PlayableTrack({
    required this.id,
    required this.title,
    this.artist = '',
    this.audioUrl,
    this.imageUrl,
    this.jamendoShareUrl,
    this.appleMusicUrl,
    this.spotifyTrackId,
    this.youtubeVideoId,
    this.playableMs = 0,
    this.sessionEligible = false,
  });

  Uri? get artUri {
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;
    return Uri.tryParse(url);
  }
}

class HandoffLink {
  final String label;
  final Uri uri;
  final HandoffKind kind;

  const HandoffLink({
    required this.label,
    required this.uri,
    required this.kind,
  });
}

enum HandoffKind { jamendo, apple, spotify, youtube }
