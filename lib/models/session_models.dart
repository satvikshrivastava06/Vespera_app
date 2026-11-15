/// Typed Dart models for VSP-012 session and feedback endpoints.
library;

import 'package:vespera/models/playable_track.dart';

class QueueItem {
  final String trackId;
  final String title;
  final String artist;
  final String? imageUrl;
  final String? audioUrl;
  final String? jamendoShareUrl;
  final int playableMs;
  final int position;
  final bool isSeed;
  final bool inSeedNeighborhood;
  final List<String> reasonCodes;

  const QueueItem({
    required this.trackId,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.audioUrl,
    this.jamendoShareUrl,
    required this.playableMs,
    required this.position,
    required this.isSeed,
    required this.inSeedNeighborhood,
    this.reasonCodes = const [],
  });

  factory QueueItem.fromJson(Map<String, dynamic> j) => QueueItem(
        trackId: j['track_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        audioUrl: j['audio_url'] as String?,
        jamendoShareUrl: j['jamendo_share_url'] as String?,
        playableMs: j['playable_ms'] as int? ?? 0,
        position: j['position'] as int? ?? 0,
        isSeed: j['is_seed'] as bool? ?? false,
        inSeedNeighborhood: j['in_seed_neighborhood'] as bool? ?? false,
        reasonCodes: (j['reason_codes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  /// Convert to a PlayableTrack for the audio player.
  PlayableTrack toPlayableTrack() => PlayableTrack(
        id: trackId,
        title: title,
        artist: artist,
        audioUrl: audioUrl,
        imageUrl: imageUrl,
        jamendoShareUrl: jamendoShareUrl,
        playableMs: playableMs,
        sessionEligible: audioUrl != null && audioUrl!.isNotEmpty,
      );
}

class SessionState {
  final String sessionId;
  final int planVersion;
  final String? intentGoal;
  final String? intentScope;
  final int? intentDurationMin;
  final int totalPlannedMs;
  final int instrumentalMs;
  final double instrumentalPct;
  final bool quotaSatisfied;
  final String? unsatisfiedNote;
  final String state;
  final List<QueueItem> queue;
  final String? traceId;

  const SessionState({
    required this.sessionId,
    required this.planVersion,
    this.intentGoal,
    this.intentScope,
    this.intentDurationMin,
    required this.totalPlannedMs,
    required this.instrumentalMs,
    required this.instrumentalPct,
    required this.quotaSatisfied,
    this.unsatisfiedNote,
    required this.state,
    this.queue = const [],
    this.traceId,
  });

  factory SessionState.fromJson(Map<String, dynamic> j) => SessionState(
        sessionId: j['session_id'] as String? ?? '',
        planVersion: j['plan_version'] as int? ?? 1,
        intentGoal: j['intent_goal'] as String?,
        intentScope: j['intent_scope'] as String?,
        intentDurationMin: j['intent_duration_min'] as int?,
        totalPlannedMs: j['total_planned_ms'] as int? ?? 0,
        instrumentalMs: j['instrumental_ms'] as int? ?? 0,
        instrumentalPct: (j['instrumental_pct'] as num?)?.toDouble() ?? 0.0,
        quotaSatisfied: j['quota_satisfied'] as bool? ?? true,
        unsatisfiedNote: j['unsatisfied_note'] as String?,
        state: j['state'] as String? ?? 'active',
        queue: (j['queue'] as List<dynamic>?)
                ?.map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        traceId: j['trace_id'] as String?,
      );

  /// Total planned duration in readable form.
  String get plannedDuration {
    final mins = totalPlannedMs ~/ 60000;
    return mins >= 60
        ? '${mins ~/ 60}h ${mins % 60}m'
        : '${mins}m';
  }
}

class FeedbackResponse {
  final String sessionId;
  final int planVersion;
  final bool replanned;
  final List<QueueItem> newQueue;
  final String message;

  const FeedbackResponse({
    required this.sessionId,
    required this.planVersion,
    required this.replanned,
    this.newQueue = const [],
    required this.message,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> j) => FeedbackResponse(
        sessionId: j['session_id'] as String? ?? '',
        planVersion: j['plan_version'] as int? ?? 1,
        replanned: j['replanned'] as bool? ?? false,
        newQueue: (j['new_queue'] as List<dynamic>?)
                ?.map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        message: j['message'] as String? ?? '',
      );
}
