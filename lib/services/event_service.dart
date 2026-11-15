/// VSP-007: Listening event ingestion.
///
/// Sends events to POST /api/v1/events authenticated by the device token.
/// Calls are fire-and-forget with silent failure — a missed telemetry event
/// must never interrupt playback or navigation.
///
/// Allowed event types mirror the backend allow-list:
///   session_created | impression | start | heartbeat | pause | complete
///   | skip | save | replay | explicit_feedback
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vespera/services/auth_service.dart';

enum VesperaEventType {
  sessionCreated,
  impression,
  start,
  heartbeat,
  pause,
  complete,
  skip,
  save,
  replay,
  explicitFeedback,
}

extension _EventTypeName on VesperaEventType {
  String get value => switch (this) {
        VesperaEventType.sessionCreated => 'session_created',
        VesperaEventType.impression => 'impression',
        VesperaEventType.start => 'start',
        VesperaEventType.heartbeat => 'heartbeat',
        VesperaEventType.pause => 'pause',
        VesperaEventType.complete => 'complete',
        VesperaEventType.skip => 'skip',
        VesperaEventType.save => 'save',
        VesperaEventType.replay => 'replay',
        VesperaEventType.explicitFeedback => 'explicit_feedback',
      };
}

enum FeedbackReason {
  notMyTaste,
  wrongContext,
  tooEnergetic,
  tooSlow,
  tooFamiliar,
  lyrics,
  alreadyHeard,
  other,
}

extension _FeedbackReasonName on FeedbackReason {
  String get value => switch (this) {
        FeedbackReason.notMyTaste => 'not_my_taste',
        FeedbackReason.wrongContext => 'wrong_context',
        FeedbackReason.tooEnergetic => 'too_energetic',
        FeedbackReason.tooSlow => 'too_slow',
        FeedbackReason.tooFamiliar => 'too_familiar',
        FeedbackReason.lyrics => 'lyrics',
        FeedbackReason.alreadyHeard => 'already_heard',
        FeedbackReason.other => 'other',
      };
}

enum SourceSurface { home, twilight, search, queue }

extension _SurfaceName on SourceSurface {
  String get value => name; // matches the backend literal exactly
}

class EventService {
  EventService({required AuthService auth}) : _auth = auth;

  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  final AuthService _auth;

  /// Send one event.  Returns true if the server accepted it (200).
  /// Failures are logged to stderr but do not propagate — telemetry must
  /// never break core features.
  Future<bool> send({
    required VesperaEventType eventType,
    String? sessionId,
    String? trackId,
    int? positionMs,
    int? durationMs,
    FeedbackReason? feedbackReason,
    String? contextId,
    SourceSurface? sourceSurface,
    String? requestId,
  }) async {
    final deviceToken = await _auth.token;
    if (deviceToken == null) {
      // Not yet bootstrapped — skip silently.
      return false;
    }

    final body = <String, dynamic>{
      'event_type': eventType.value,
      'occurred_at_utc': DateTime.now().toUtc().toIso8601String(),
    };
    if (sessionId != null) body['session_id'] = sessionId;
    if (trackId != null) body['track_id'] = trackId;
    if (positionMs != null) body['position_ms'] = positionMs;
    if (durationMs != null) body['duration_ms'] = durationMs;
    if (feedbackReason != null) body['feedback_reason'] = feedbackReason.value;
    if (contextId != null) body['context_id'] = contextId;
    if (sourceSurface != null) body['source_surface'] = sourceSurface.value;
    if (requestId != null) body['request_id'] = requestId;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/events'),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-Token': deviceToken,
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      // Network failure, timeout, etc. — never propagate.
      return false;
    }
  }
}
