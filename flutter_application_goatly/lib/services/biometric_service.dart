import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Wraps Android BiometricPrompt / iOS LocalAuthentication via local_auth.
/// Supports fingerprint sensor and face recognition camera.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _keyEnabled = 'biometric_enabled';
  static const _keyEmail = 'biometric_email';

  // ── Hardware & enrollment check ──────────────────────────────────────────

  /// Returns true if the device has biometric hardware AND has enrolled
  /// at least one biometric (fingerprint or face).
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Authentication ────────────────────────────────────────────────────────

  /// Triggers the system biometric prompt (fingerprint or face recognition).
  /// [localizedReason] is the message shown in the system dialog.
  /// Returns true on success, false on failure or cancellation.
  static Future<bool> authenticate({
    String localizedReason =
        'Confirma tu identidad para acceder a Goatly',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,     // keeps prompt alive if app goes background
          biometricOnly: true,  // no PIN/pattern fallback — biometric only
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Preferences ───────────────────────────────────────────────────────────

  /// Whether the user has opted-in to biometric login.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// Enable or disable biometric login.
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  /// Persist the email so we can restore the session after biometric auth.
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  /// Retrieve the last saved email.
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Stores the JWT refresh token in flutter_secure_storage (Android Keystore / iOS Keychain).
  static Future<void> saveRefreshToken(String refreshToken) =>
      SecureStorageService.saveTokens(refreshToken: refreshToken, accessToken: '');

  /// Retrieves the JWT refresh token from secure storage.
  static Future<String?> getSavedRefreshToken() =>
      SecureStorageService.getRefreshToken();

  /// Clear all stored biometric preferences (called on logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyEmail);
    await SecureStorageService.clearTokens();
  }
}
