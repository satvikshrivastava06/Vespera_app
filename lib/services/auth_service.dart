/// VSP-007: Anonymous device-bound token lifecycle.
///
/// On first launch, calls POST /api/v1/auth/anonymous to obtain an opaque
/// token and a pseudonymous user_id.  Both are stored in platform secure
/// storage (flutter_secure_storage) and reused on every subsequent launch.
///
/// The raw token is attached to outbound requests via the X-Device-Token
/// header.  It is never logged, never sent in a URL, and never placed in
/// the request body.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = String.fromEnvironment(
    'VESPERA_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'vespera_device_token';
  static const _userIdKey = 'vespera_user_id';

  // Cached in-memory after first read to avoid repeated secure-storage I/O.
  String? _cachedToken;
  String? _cachedUserId;

  /// Returns the stored token, or null if the device has not been
  /// bootstrapped yet.
  Future<String?> get token async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// Returns the pseudonymous user_id derived from the token, or null
  /// before bootstrap.
  Future<String?> get userId async {
    _cachedUserId ??= await _storage.read(key: _userIdKey);
    return _cachedUserId;
  }

  /// Ensures a device token exists, creating one if this is the first run.
  /// Safe to call on every app start; it is a no-op when a token already
  /// exists.
  Future<void> ensureBootstrapped() async {
    final existing = await token;
    if (existing != null) return;
    await _bootstrap();
  }

  /// Forces a fresh bootstrap (use only after explicit token revocation).
  Future<void> forceRebootstrap() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    _cachedToken = null;
    _cachedUserId = null;
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final uri = Uri.parse('$_baseUrl/auth/anonymous');
    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(
        'Auth bootstrap failed (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final rawToken = body['token'] as String;
    final newUserId = body['user_id'] as String;

    await _storage.write(key: _tokenKey, value: rawToken);
    await _storage.write(key: _userIdKey, value: newUserId);
    _cachedToken = rawToken;
    _cachedUserId = newUserId;
  }
}
