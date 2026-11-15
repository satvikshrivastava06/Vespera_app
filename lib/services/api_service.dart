import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vespera/models/catalog_track.dart';
import 'package:vespera/models/home_feed.dart';
import 'package:vespera/services/auth_service.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // Set at build time with:
  //   flutter run --dart-define=VESPERA_API_BASE_URL=https://your-backend.example.com/api/v1
  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  final AuthService _auth;

  ApiService({AuthService? auth}) : _auth = auth ?? AuthService();

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns the common headers for every authenticated request.
  /// The device token is attached as X-Device-Token; it is never placed in
  /// the URL or logged.
  Future<Map<String, String>> _authHeaders([
    Map<String, String>? extra,
  ]) async {
    final token = await _auth.token;
    final headers = <String, String>{
      ...?extra,
    };
    if (token != null) {
      headers['X-Device-Token'] = token;
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Existing endpoints — now carry the device token
  // ---------------------------------------------------------------------------

  Future<HomeFeedResponse> fetchHomeFeed({
    String localTime = '',
    String weather = 'Clear',
    String location = '',
    int activityBpm = 70,
  }) async {
    final url = Uri.parse('$_baseUrl/home_feed');
    try {
      final headers = await _authHeaders({
        'local-time': localTime.isEmpty ? DateTime.now().toIso8601String() : localTime,
        'weather': weather,
        'location': location,
        'activity-bpm': activityBpm.toString(),
      });
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw ApiException('Home feed failed (HTTP ${response.statusCode})');
      }
      return HomeFeedResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server');
    }
  }

  Future<ExploreFeedResponse> fetchExploreFeed() async {
    final url = Uri.parse('$_baseUrl/explore_feed');
    try {
      final headers = await _authHeaders();
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw ApiException('Explore feed failed (HTTP ${response.statusCode})');
      }
      return ExploreFeedResponse.fromJson(json.decode(response.body));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server');
    }
  }

  Future<List<CatalogTrack>> fetchCatalog() async {
    final url = Uri.parse('$_baseUrl/catalog');
    try {
      final headers = await _authHeaders();
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw ApiException('Catalog failed (HTTP ${response.statusCode})');
      }
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((row) => CatalogTrack.fromJson(row as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server');
    }
  }

  Future<List<PlaylistItem>> search(String query, {String type = "all"}) async {
    final url = Uri.parse(
        '$_baseUrl/search?query=${Uri.encodeComponent(query)}&search_type=$type');
    try {
      final headers = await _authHeaders();
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw ApiException('Search failed (HTTP ${response.statusCode})');
      }
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PlaylistItem.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server');
    }
  }
}
