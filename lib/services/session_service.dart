/// VSP-012: Session service — create sessions, fetch state, submit feedback.
///
/// Every call attaches the X-Device-Token header from AuthService.
/// Failures return null / empty rather than throwing so the UI can degrade
/// gracefully without crashing playback.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vespera/models/session_models.dart';
import 'package:vespera/services/auth_service.dart';

enum SkipReason {
  notMyTaste,
  wrongContext,
  tooEnergetic,
  tooSlow,
  tooFamiliar,
  lyrics,
  alreadyHeard,
  other,
}

extension SkipReasonValue on SkipReason {
  String get value => switch (this) {
        SkipReason.notMyTaste => 'not_my_taste',
        SkipReason.wrongContext => 'wrong_context',
        SkipReason.tooEnergetic => 'too_energetic',
        SkipReason.tooSlow => 'too_slow',
        SkipReason.tooFamiliar => 'too_familiar',
        SkipReason.lyrics => 'lyrics',
        SkipReason.alreadyHeard => 'already_heard',
        SkipReason.other => 'other',
      };

  String get label => switch (this) {
        SkipReason.notMyTaste => 'Not my taste',
        SkipReason.wrongContext => 'Wrong context',
        SkipReason.tooEnergetic => 'Too energetic',
        SkipReason.tooSlow => 'Too slow',
        SkipReason.tooFamiliar => 'Too familiar',
        SkipReason.lyrics => 'Lyrics',
        SkipReason.alreadyHeard => 'Already heard',
        SkipReason.other => 'Other',
      };
}

class SessionService {
  SessionService({AuthService? auth}) : _auth = auth ?? AuthService();

  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  final AuthService _auth;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.token;
    return {
      'Content-Type': 'application/json',
      'X-Device-Token': token ?? '',
    }..removeWhere((_, v) => v.isEmpty);
  }

  /// Create a new session from a natural-language request.
  /// [seedTrackIds] is the 3-5 user-selected seed tracks.
  Future<SessionState?> createSession({
    required String text,
    List<String> seedTrackIds = const [],
    String? requestId,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/sessions'),
            headers: await _headers(),
            body: json.encode({
              'text': text,
              'seed_track_ids': seedTrackIds,
              'request_id': requestId,
            }..removeWhere((_, v) => v == null)),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 201) {
        return SessionState.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch current session state and queue.
  Future<SessionState?> getSession(String sessionId) async {
    try {
      final resp = await http
          .get(
            Uri.parse('$_baseUrl/sessions/$sessionId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        return SessionState.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit a skip reason. Returns the feedback response with the new queue,
  /// or null on network failure.
  Future<FeedbackResponse?> submitFeedback({
    required String sessionId,
    required String trackId,
    required SkipReason reason,
    int? positionMs,
  }) async {
    try {
      final body = <String, dynamic>{
        'track_id': trackId,
        'feedback_reason': reason.value,
        'position_ms': positionMs,
      }..removeWhere((_, v) => v == null);
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/sessions/$sessionId/feedback'),
            headers: await _headers(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return FeedbackResponse.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
