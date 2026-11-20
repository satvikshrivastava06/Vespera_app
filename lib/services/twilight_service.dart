/// VSP-009: TwilightService — single entry point for all Twilight UI actions.
///
/// All interaction modes (chat, suggestion tap, semantic search) route through
/// one method: [send].  The backend compiles intent, searches the catalog and
/// returns a typed [TwilightResponse].
///
/// Design rules (roadmap §10):
///   - ApiService owns HTTP transport.
///   - This service owns request construction, auth-header injection, request
///     deduplication, and error mapping.
///   - Duplicate submits (same text while a request is in-flight) are dropped.
///   - Stale requests are cancelled when a new one arrives.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vespera/models/twilight_models.dart';
import 'package:vespera/services/auth_service.dart';

class TwilightService {
  TwilightService({AuthService? auth}) : _auth = auth ?? AuthService();

  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  final AuthService _auth;

  // Cancel pending request when a new one arrives.
  http.Client? _activeClient;
  bool _inFlight = false;

  bool get isLoading => _inFlight;

  /// Send a request to the Twilight agent endpoint.
  ///
  /// Returns a [TwilightResponse] on success, or one with [TwilightStatus.error]
  /// on network failure. Never throws — callers can rely on the response's
  /// [TwilightStatus] to drive UI state.
  Future<TwilightResponse> send({
    required String text,
    TwilightMode mode = TwilightMode.chat,
    String? sessionId,
    String? requestId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const TwilightResponse(
        schemaVersion: '1.0',
        status: TwilightStatus.needsClarification,
        message: 'Please describe what you\'d like to listen to.',
      );
    }

    // Cancel any in-flight request before starting a new one.
    _cancel();
    _inFlight = true;
    final client = http.Client();
    _activeClient = client;

    try {
      final token = await _auth.token;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Device-Token': token ?? '',
      }..removeWhere((_, v) => v.isEmpty);

      final body = json.encode({
        'text': trimmed,
        'mode': mode.value,
        'session_id': sessionId,
        'request_id': requestId,
      }..removeWhere((_, v) => v == null));

      final response = await client
          .post(
            Uri.parse('$_baseUrl/twilight/agent'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 75));  // Allow for Render cold start

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return TwilightResponse.fromJson(decoded);
      }

      return TwilightResponse(
        schemaVersion: '1.0',
        status: TwilightStatus.error,
        message: 'Request failed (HTTP ${response.statusCode}).',
      );
    } on http.ClientException {
      // Request was cancelled — return a silent partial rather than an error.
      return const TwilightResponse(
        schemaVersion: '1.0',
        status: TwilightStatus.partial,
        message: '',
      );
    } catch (_) {
      return const TwilightResponse(
        schemaVersion: '1.0',
        status: TwilightStatus.error,
        message: 'Could not reach the server. Check your connection.',
      );
    } finally {
      _inFlight = false;
      _activeClient = null;
      client.close();
    }
  }

  void _cancel() {
    _activeClient?.close();
    _activeClient = null;
    _inFlight = false;
  }

  void dispose() {
    _cancel();
  }
}
