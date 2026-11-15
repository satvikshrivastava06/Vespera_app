/// Typed Dart models mirroring app/schemas/twilight.py.
///
/// schema_version is checked on parse so Flutter can detect incompatible
/// future shapes instead of silently casting unvalidated maps.
library;

enum TwilightMode { chat, suggestion, semanticSearch }

extension TwilightModeValue on TwilightMode {
  String get value => switch (this) {
        TwilightMode.chat => 'chat',
        TwilightMode.suggestion => 'suggestion',
        TwilightMode.semanticSearch => 'semantic_search',
      };
}

enum TwilightStatus { ready, needsClarification, partial, error }

extension _TwilightStatusParse on TwilightStatus {
  static TwilightStatus fromString(String s) => switch (s) {
        'ready' => TwilightStatus.ready,
        'needs_clarification' => TwilightStatus.needsClarification,
        'partial' => TwilightStatus.partial,
        _ => TwilightStatus.error,
      };
}

class TwilightTrackResult {
  final String trackId;
  final String title;
  final String artist;
  final String playbackMode;
  final bool sessionEligible;
  final int playableMs;
  final String? audioUrl;
  final String? jamendoShareUrl;
  final String? imageUrl;
  final List<String> reasonCodes;

  const TwilightTrackResult({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.playbackMode,
    required this.sessionEligible,
    required this.playableMs,
    this.audioUrl,
    this.jamendoShareUrl,
    this.imageUrl,
    this.reasonCodes = const [],
  });

  factory TwilightTrackResult.fromJson(Map<String, dynamic> j) =>
      TwilightTrackResult(
        trackId: j['track_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        playbackMode: j['playback_mode'] as String? ?? '',
        sessionEligible: j['session_eligible'] as bool? ?? false,
        playableMs: j['playable_ms'] as int? ?? 0,
        audioUrl: j['audio_url'] as String?,
        jamendoShareUrl: j['jamendo_share_url'] as String?,
        imageUrl: j['image_url'] as String?,
        reasonCodes: (j['reason_codes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

class TwilightResponse {
  final String schemaVersion;
  final String? requestId;
  final String? traceId;
  final TwilightStatus status;
  final String message;
  final String? intentGoal;
  final String? intentScope;
  final String? intentEnergy;
  final int? intentDurationMin;
  final bool? intentRequireInstrumental;
  final List<String> intentExcludedGenres;
  final List<String> intentNegations;
  final String? sessionId;
  final List<TwilightTrackResult> tracks;
  final List<String> unverifiedConstraints;
  final List<String> nextActions;

  const TwilightResponse({
    required this.schemaVersion,
    this.requestId,
    this.traceId,
    required this.status,
    required this.message,
    this.intentGoal,
    this.intentScope,
    this.intentEnergy,
    this.intentDurationMin,
    this.intentRequireInstrumental,
    this.intentExcludedGenres = const [],
    this.intentNegations = const [],
    this.sessionId,
    this.tracks = const [],
    this.unverifiedConstraints = const [],
    this.nextActions = const [],
  });

  factory TwilightResponse.fromJson(Map<String, dynamic> j) {
    return TwilightResponse(
      schemaVersion: j['schema_version'] as String? ?? '1.0',
      requestId: j['request_id'] as String?,
      traceId: j['trace_id'] as String?,
      status: _TwilightStatusParse.fromString(
          j['status'] as String? ?? 'error'),
      message: j['message'] as String? ?? '',
      intentGoal: j['intent_goal'] as String?,
      intentScope: j['intent_scope'] as String?,
      intentEnergy: j['intent_energy'] as String?,
      intentDurationMin: j['intent_duration_min'] as int?,
      intentRequireInstrumental: j['intent_require_instrumental'] as bool?,
      intentExcludedGenres: (j['intent_excluded_genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      intentNegations: (j['intent_negations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sessionId: j['session_id'] as String?,
      tracks: (j['tracks'] as List<dynamic>?)
              ?.map((e) =>
                  TwilightTrackResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      unverifiedConstraints:
          (j['unverified_constraints'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      nextActions: (j['next_actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
              const [],
    );
  }
}
