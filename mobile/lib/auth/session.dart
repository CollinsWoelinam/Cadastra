import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SessionUser {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const SessionUser(this.id, this.email, this.fullName, this.role);

  SessionUser.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        email = j['email'] as String,
        fullName = j['full_name'] as String,
        role = j['role'] as String;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'full_name': fullName, 'role': role};
}

/// The session can no longer reach the API; the surveyor must sign in again.
class AuthRequiredException implements Exception {
  @override
  String toString() => 'Sign in again to upload surveys.';
}

/// Where tokens are kept between launches.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

/// iOS Keychain / Android Keystore-backed storage.
class SecureTokenStore implements TokenStore {
  static const _key = 'cadastra_session';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemoryTokenStore implements TokenStore {
  String? value;

  MemoryTokenStore([this.value]);

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String v) async => value = v;

  @override
  Future<void> clear() async => value = null;
}

/// Signed-in state for the field app. Capture works without a session; only
/// uploading needs one, so an expired session never interrupts a survey.
class AuthSession extends ChangeNotifier {
  static const fieldRoles = {'SURVEYOR', 'ADMIN'};

  final String baseUrl;
  final TokenStore store;
  final http.Client _http;

  SessionUser? user;
  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshing;

  /// True when the last refresh failed: [user] is kept for display and for scoping
  /// local surveys, but uploads wait until the surveyor signs in again.
  bool expired = false;

  AuthSession(this.baseUrl, this.store, [http.Client? client]) : _http = client ?? http.Client();

  bool get signedIn => user != null;
  String? get accessToken => expired ? null : _accessToken;

  Future<void> load() async {
    final raw = await store.read();
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      user = SessionUser.fromJson(j['user'] as Map<String, dynamic>);
      _accessToken = j['access_token'] as String?;
      _refreshToken = j['refresh_token'] as String?;
      expired = _refreshToken == null;
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> login(String email, String password) async {
    final http.Response res;
    try {
      res = await _http
          .post(Uri.parse('$baseUrl/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email.trim(), 'password': password}))
          .timeout(const Duration(seconds: 20));
    } on Exception {
      return 'Cannot reach the registry. Check your connection and try again.';
    }
    if (res.statusCode == 401) return 'Incorrect email or password.';
    if (res.statusCode == 429) {
      final minutes = ((int.tryParse(res.headers['retry-after'] ?? '') ?? 900) / 60).ceil();
      return 'Too many sign-in attempts. Try again in $minutes minute${minutes == 1 ? '' : 's'}.';
    }
    if (res.statusCode != 200) return 'Sign-in failed (HTTP ${res.statusCode}).';
    final pair = jsonDecode(res.body) as Map<String, dynamic>;
    final signedIn = SessionUser.fromJson(pair['user'] as Map<String, dynamic>);
    if (!fieldRoles.contains(signedIn.role)) {
      // Don't leave a usable session behind for an account that can't submit.
      await _revoke(pair['refresh_token'] as String);
      return 'This account (${signedIn.role.toLowerCase()}) cannot submit surveys. Use a surveyor account.';
    }
    await _adopt(pair);
    return null;
  }

  /// Rotates the refresh token. Concurrent callers share one refresh, because the
  /// API treats reuse of a rotated token as theft and ends every session.
  Future<bool> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final token = _refreshToken;
    if (token == null) return false;
    final http.Response res;
    try {
      res = await _http
          .post(Uri.parse('$baseUrl/auth/refresh'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': token}))
          .timeout(const Duration(seconds: 20));
    } on Exception {
      return false; // Offline: keep the tokens and try again later.
    }
    if (res.statusCode == 200) {
      await _adopt(jsonDecode(res.body) as Map<String, dynamic>);
      return true;
    }
    if (res.statusCode == 401) {
      _accessToken = _refreshToken = null;
      expired = true;
      await _persist();
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    final token = _refreshToken;
    user = _accessToken = _refreshToken = null;
    expired = false;
    await store.clear();
    notifyListeners();
    if (token != null) await _revoke(token);
  }

  Future<void> _adopt(Map<String, dynamic> pair) async {
    user = SessionUser.fromJson(pair['user'] as Map<String, dynamic>);
    _accessToken = pair['access_token'] as String;
    _refreshToken = pair['refresh_token'] as String;
    expired = false;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => store.write(jsonEncode({
        'user': user?.toJson(),
        'access_token': _accessToken,
        'refresh_token': _refreshToken,
      }));

  Future<void> _revoke(String refreshToken) async {
    try {
      await _http
          .post(Uri.parse('$baseUrl/auth/logout'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': refreshToken}))
          .timeout(const Duration(seconds: 10));
    } on Exception {
      // Best effort; the token expires on its own.
    }
  }
}
