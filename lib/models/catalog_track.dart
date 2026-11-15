class CatalogTrack {
  final String id;
  final String title;
  final String artist;
  final String? imageUrl;
  final String? audioUrl;
  final String? jamendoShareUrl;
  final int playableMs;
  final bool sessionEligible;
  final String? instrumentalLabel;

  const CatalogTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.audioUrl,
    this.jamendoShareUrl,
    this.playableMs = 0,
    this.sessionEligible = false,
    this.instrumentalLabel,
  });

  factory CatalogTrack.fromJson(Map<String, dynamic> json) {
    return CatalogTrack(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      jamendoShareUrl: json['jamendo_share_url'] as String?,
      playableMs: json['playable_ms'] as int? ?? 0,
      sessionEligible: json['session_eligible'] as bool? ?? false,
      instrumentalLabel: json['instrumental_label'] as String?,
    );
  }
}
