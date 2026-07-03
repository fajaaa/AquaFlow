import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access/refresh tokens in the platform secure store
/// (Keychain on iOS/macOS, Keystore-backed EncryptedSharedPreferences on
/// Android, Credential Locker on Windows, libsecret on Linux).
///
/// This is the only place tokens are read from or written to disk. Tokens are
/// never kept in SharedPreferences or a plain file, and their values are never
/// printed or logged.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'aquaflow.accessToken';
  static const _refreshTokenKey = 'aquaflow.refreshToken';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Removes both tokens from the secure store (logout).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
