import 'package:flutter/foundation.dart';

import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_exception.dart';
import '../services/token_storage.dart';

/// Where the app is in the auth lifecycle. [unknown] is the initial state while
/// [bootstrap] checks the secure store; the UI shows a splash until it resolves.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns all authentication state and is the single source of truth the UI
/// listens to. Handles startup restore, login, logout and silent refresh.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthApiService? authService, TokenStorage? tokenStorage})
      : _authService = authService ?? AuthApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthApiService _authService;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called once at startup. Restores a session from stored tokens: uses the
  /// access token while it is still valid, otherwise tries the refresh token,
  /// and falls back to unauthenticated if neither works.
  Future<void> bootstrap() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken != null && _trySetSession(accessToken)) {
      _setStatus(AuthStatus.authenticated);
      return;
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null && await _tryRefresh(refreshToken)) {
      return;
    }

    await _tokenStorage.clear();
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Attempts a login. Returns true on success; on failure [errorMessage] holds
  /// a user-facing reason and the status stays unauthenticated.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      final tokens = await _authService.login(email.trim(), password);
      await _persistAndActivate(tokens);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Registers a new Customer, then immediately logs in with the same
  /// credentials (the backend register endpoint returns the created user, not
  /// tokens) so the caller lands in an authenticated session. Returns true on
  /// success; on failure [errorMessage] holds a user-facing reason.
  Future<bool> register({
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      await _authService.register(
        email: email.trim(),
        password: password,
        phone: phone.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
      final tokens = await _authService.login(email.trim(), password);
      await _persistAndActivate(tokens);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _session = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<bool> _tryRefresh(String refreshToken) async {
    try {
      final tokens = await _authService.refresh(refreshToken);
      await _persistAndActivate(tokens);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistAndActivate(AuthResult tokens) async {
    await _tokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
    _session = AuthSession.fromAccessToken(tokens.accessToken);
    _setStatus(AuthStatus.authenticated);
  }

  /// Decodes [accessToken] into a session, rejecting expired/invalid tokens.
  bool _trySetSession(String accessToken) {
    try {
      final session = AuthSession.fromAccessToken(accessToken);
      if (session.expiresAt.isBefore(DateTime.now())) return false;
      _session = session;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
