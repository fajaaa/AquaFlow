import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'auth_api_service.dart';
import 'auth_exception.dart';
import 'token_storage.dart';

/// What happened to one `POST /Access/refresh` attempt.
enum SessionRefreshStatus {
  /// New tokens were issued and stored.
  refreshed,

  /// The refresh token is invalid, expired, revoked, or missing - the session
  /// is over. Tokens have been cleared.
  invalid,

  /// The refresh could not be completed (network failure, timeout, rate
  /// limit, server error). The session is kept; the caller may retry later.
  unavailable,
}

class SessionRefreshResult {
  const SessionRefreshResult._(
    this.status, {
    this.accessToken,
    this.errorMessage,
    this.statusCode,
    this.isNetworkError = false,
  });

  const SessionRefreshResult.refreshed(String accessToken)
    : this._(SessionRefreshStatus.refreshed, accessToken: accessToken);

  const SessionRefreshResult.invalid() : this._(SessionRefreshStatus.invalid);

  const SessionRefreshResult.unavailable(
    String message, {
    int? statusCode,
    bool isNetworkError = false,
  }) : this._(
         SessionRefreshStatus.unavailable,
         errorMessage: message,
         statusCode: statusCode,
         isNetworkError: isNetworkError,
       );

  final SessionRefreshStatus status;

  /// The new access token when [status] is [SessionRefreshStatus.refreshed].
  final String? accessToken;

  /// User-safe reason when [status] is [SessionRefreshStatus.unavailable].
  final String? errorMessage;

  /// HTTP status of the failed refresh, when the server answered at all.
  final int? statusCode;

  /// True when the refresh never got an HTTP answer (offline, timeout).
  final bool isNetworkError;
}

/// The one place that exchanges the refresh token for a new token pair.
///
/// Used by both `AuthenticatedClient` (proactive refresh before a request and
/// reactive refresh after a 401) and `AuthProvider.bootstrap()`, so there is
/// exactly one refresh code path in the app. Refreshes are single-flight:
/// while one `POST /Access/refresh` is in flight, every other caller awaits
/// the same result instead of sending its own - the backend rotates the
/// presented refresh token, so a second concurrent refresh with the same
/// token would be rejected and look like an expired session.
///
/// One shared instance per app ([instance]); `AuthProvider` hooks
/// [onTokensRefreshed] (to re-decode the session - a new JWT can carry new
/// `Permission` claims) and [onSessionExpired] (to sign the user out).
class SessionManager {
  SessionManager({AuthApiService? authService, TokenStorage? tokenStorage})
    : _authService =
          authService ?? AuthApiService(timeout: const Duration(seconds: 10)),
      _tokenStorage = tokenStorage ?? TokenStorage();

  /// The app-wide instance used by `AuthenticatedClient.instance` and
  /// `AuthProvider`.
  static final SessionManager instance = SessionManager();

  final AuthApiService _authService;
  final TokenStorage _tokenStorage;

  Completer<SessionRefreshResult>? _inFlight;

  /// Called with the new access token after every successful refresh.
  void Function(String accessToken)? onTokensRefreshed;

  /// Called once per failed refresh whose refresh token was rejected (400/401
  /// from `/Access/refresh`), after the tokens were cleared. Never called for
  /// a network failure, and never when there was no session to begin with.
  void Function()? onSessionExpired;

  TokenStorage get tokenStorage => _tokenStorage;

  /// The stored access token, without any refresh.
  Future<String?> currentAccessToken() => _tokenStorage.getAccessToken();

  /// The stored access token, refreshed first when it expires within
  /// [minValidity]. Falls back to the current token when the refresh is
  /// [SessionRefreshStatus.unavailable] (it may still be valid for a few
  /// seconds), and returns null once the session turned out to be invalid.
  Future<String?> validAccessToken({
    Duration minValidity = const Duration(seconds: 30),
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || !_expiresWithin(token, minValidity)) return token;

    final result = await refresh();
    switch (result.status) {
      case SessionRefreshStatus.refreshed:
        return result.accessToken;
      case SessionRefreshStatus.invalid:
        return null;
      case SessionRefreshStatus.unavailable:
        return token;
    }
  }

  /// Exchanges the stored refresh token for a new pair (single-flight - see
  /// the class comment). Never throws.
  Future<SessionRefreshResult> refresh() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<SessionRefreshResult>();
    _inFlight = completer;
    _performRefresh().then(completer.complete).whenComplete(() {
      if (identical(_inFlight, completer)) _inFlight = null;
    });
    return completer.future;
  }

  Future<SessionRefreshResult> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return const SessionRefreshResult.invalid();

    try {
      final tokens = await _authService.refresh(refreshToken);

      // A logout (or a new login) finished while this refresh was in flight:
      // never write the old session back to storage.
      if (await _tokenStorage.getRefreshToken() != refreshToken) {
        final current = await _tokenStorage.getAccessToken();
        return current == null
            ? const SessionRefreshResult.invalid()
            : SessionRefreshResult.refreshed(current);
      }

      await _tokenStorage.replaceTokens(
        tokens.accessToken,
        tokens.refreshToken,
      );
      _safely(() => onTokensRefreshed?.call(tokens.accessToken));
      return SessionRefreshResult.refreshed(tokens.accessToken);
    } on AuthException catch (e) {
      final statusCode = e.statusCode;
      if (statusCode == 400 || statusCode == 401) {
        // Same guard as above: a session that was replaced in the meantime is
        // not the one that expired.
        if (await _tokenStorage.getRefreshToken() == refreshToken) {
          await _tokenStorage.clear();
          _safely(() => onSessionExpired?.call());
        }
        return const SessionRefreshResult.invalid();
      }
      // No status code = AuthApiService mapped a transport failure
      // (SocketException/timeout/ClientException) - the session is kept.
      return SessionRefreshResult.unavailable(
        e.message,
        statusCode: statusCode,
        isNetworkError: statusCode == null,
      );
    } catch (e) {
      // E.g. a 200 with a malformed body - not proof the session is gone.
      debugPrint('Session refresh failed: $e');
      return const SessionRefreshResult.unavailable('Session refresh failed.');
    }
  }

  static bool _expiresWithin(String token, Duration window) {
    try {
      return JwtDecoder.getExpirationDate(
        token,
      ).isBefore(DateTime.now().add(window));
    } catch (_) {
      // Not a decodable JWT - send it as-is and let the backend decide.
      return false;
    }
  }

  static void _safely(void Function() callback) {
    try {
      callback();
    } catch (e) {
      debugPrint('Session callback failed: $e');
    }
  }
}
