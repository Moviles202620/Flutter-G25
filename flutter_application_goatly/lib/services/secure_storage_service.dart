import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tier-2 local storage using flutter_secure_storage (Android Keystore / iOS Keychain).
///
/// Stores JWT tokens encrypted at rest so biometric offline unlock can verify
/// a cached session without a network call.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'jwt_access_token';
  static const _keyRefreshToken = 'jwt_refresh_token';
  static const _keyTokenExpiry = 'token_expiry';

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    String refreshToken = '',
    DateTime? expiry,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(
      key: _keyTokenExpiry,
      value: (expiry ?? DateTime.now().add(const Duration(minutes: 15))).toIso8601String(),
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  static Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  /// Returns true when a non-expired token exists in secure storage.
  /// Used by biometric offline unlock to skip the network call.
  static Future<bool> hasValidToken() async {
    final raw = await _storage.read(key: _keyTokenExpiry);
    if (raw == null) return false;
    final expiry = DateTime.tryParse(raw);
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiry);
  }

  /// Saves a synthetic "session" token from a plain login so that biometric
  /// unlock can validate the session on subsequent offline opens.
  static Future<void> saveSession(String email) async {
    await saveTokens(
      accessToken: 'local_session_$email',
      expiry: DateTime.now().add(const Duration(days: 7)),
    );
  }

  static Future<bool> hasSession() async {
    final token = await _storage.read(key: _keyAccessToken);
    return token != null && token.isNotEmpty;
  }
}
