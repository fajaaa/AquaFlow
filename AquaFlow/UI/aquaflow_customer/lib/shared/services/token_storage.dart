import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access/refresh tokens in the platform secure store
/// (Keychain on iOS/macOS, Keystore-backed EncryptedSharedPreferences on
/// Android, Credential Locker on Windows, libsecret on Linux).
///
/// This is the only place tokens are read from or written to disk. Tokens are
/// never kept in SharedPreferences or a plain file, and their values are never
/// printed or logged.
///
/// "Remember me" is implemented here rather than in [AuthProvider]: when the
/// caller opts out (`remember: false`), tokens are kept in memory only for the
/// life of the app process (so silent refresh/logout still work normally this
/// run) and never written to disk, so a cold app restart finds nothing to
/// restore and falls back to the login screen instead of silently resuming
/// the session.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'aquaflow.accessToken';
  static const _refreshTokenKey = 'aquaflow.refreshToken';
  static const _rememberedEmailKey = 'aquaflow.rememberedEmail';

  String? _memoryAccessToken;
  String? _memoryRefreshToken;

  Future<void> saveTokens(
    String accessToken,
    String refreshToken, {
    bool remember = true,
  }) async {
    if (remember) {
      _memoryAccessToken = null;
      _memoryRefreshToken = null;
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } else {
      // Wipe any tokens left over from a previously "remembered" session so
      // that session can't be silently restored on the next cold start.
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      _memoryAccessToken = accessToken;
      _memoryRefreshToken = refreshToken;
    }
  }

  Future<String?> getAccessToken() async {
    if (_memoryAccessToken != null) return _memoryAccessToken;
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (_memoryRefreshToken != null) return _memoryRefreshToken;
    return _storage.read(key: _refreshTokenKey);
  }

  /// Removes both tokens from the secure store and memory (logout).
  Future<void> clear() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Remembers the email used to log in so the login screen can pre-fill it
  /// next time. Pass `null`/empty to forget it (e.g. "remember me" unchecked).
  Future<void> saveRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _storage.delete(key: _rememberedEmailKey);
    } else {
      await _storage.write(key: _rememberedEmailKey, value: email);
    }
  }

  Future<String?> getRememberedEmail() =>
      _storage.read(key: _rememberedEmailKey);
}
