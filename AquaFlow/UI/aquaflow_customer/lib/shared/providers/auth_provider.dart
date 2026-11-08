import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_exception.dart';
import '../services/preferences_api_service.dart';
import '../services/push_notification_service.dart';
import '../services/session_manager.dart';
import '../services/token_storage.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';

/// Where the app is in the auth lifecycle. [unknown] is the initial state while
/// [bootstrap] checks the secure store; the UI shows a splash until it resolves.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns all authentication state and is the single source of truth the UI
/// listens to. Handles startup restore, login and logout; the silent refresh
/// itself lives in [SessionManager] (shared with `AuthenticatedClient`), and
/// this provider follows its results: a refresh re-decodes [session] (the new
/// JWT can carry different `Permission` claims or role), and a rejected
/// refresh token signs the user out once and calls [onSessionExpired].
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthApiService? authService,
    TokenStorage? tokenStorage,
    SessionManager? sessionManager,
    PushNotificationService? pushNotificationService,
    PreferencesApiService? preferencesService,
    ThemeProvider? themeProvider,
    LocaleProvider? localeProvider,
    this.onSessionExpired,
  }) : _authService = authService ?? AuthApiService(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _sessionManager = sessionManager ?? SessionManager.instance,
       _pushService = pushNotificationService ?? PushNotificationService(),
       _preferencesService = preferencesService ?? PreferencesApiService(),
       _themeProvider = themeProvider ?? ThemeProvider(),
       _localeProvider = localeProvider ?? LocaleProvider() {
    _sessionManager.onTokensRefreshed = _handleTokensRefreshed;
    _sessionManager.onSessionExpired = _handleSessionExpired;
  }

  final AuthApiService _authService;
  final TokenStorage _tokenStorage;
  final SessionManager _sessionManager;

  /// UI hook for an involuntary sign-out (refresh token rejected while the
  /// app was in use) - `main.dart` shows the "session expired" SnackBar and
  /// pops any pushed routes. Not called for a regular [logout].
  final VoidCallback? onSessionExpired;
  final PushNotificationService _pushService;
  final PreferencesApiService _preferencesService;
  // Shared with `main.dart`'s widget tree (passed in, not created there) so
  // applying the fetched theme here actually repaints the app.
  final ThemeProvider _themeProvider;
  // Same reasoning as [_themeProvider], for `UserPreference.Language`.
  final LocaleProvider _localeProvider;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  bool _isBusy = false;
  bool _isLoggingOut = false;
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
      _registerPushToken();
      _applyThemePreference();
      _applyLanguagePreference();
      return;
    }

    // Same refresh path (and single-flight guard) as AuthenticatedClient;
    // SessionManager stores the new pair itself.
    final result = await _sessionManager.refresh();
    final refreshedToken = result.accessToken;
    if (refreshedToken != null) {
      try {
        _activate(refreshedToken);
        return;
      } catch (_) {
        // Undecodable token - fall through to signed out.
      }
    }

    await _tokenStorage.clear();
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Attempts a login. Returns true on success; on failure [errorMessage] holds
  /// a user-facing reason and the status stays unauthenticated.
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      final trimmedEmail = email.trim();
      final tokens = await _authService.login(trimmedEmail, password);
      await _persistAndActivate(tokens, rememberMe: rememberMe);
      await _tokenStorage.saveRememberedEmail(
        rememberMe ? trimmedEmail : null,
      );
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
  /// tokens) so the caller lands in an authenticated session. [theme] seeds
  /// the new user's `UserPreference.Theme` on the backend. Returns true on
  /// success; on failure [errorMessage] holds a user-facing reason.
  Future<bool> register({
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
    required String theme,
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
        theme: theme,
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

  /// The email from the last "remember me" login, if any, so the login
  /// screen can pre-fill it.
  Future<String?> getRememberedEmail() => _tokenStorage.getRememberedEmail();

  Future<void> logout() async {
    // While this runs, a 401 + failed refresh (e.g. right after a password
    // change revoked every session) must not be treated as "session expired"
    // on top of the logout the user asked for.
    _isLoggingOut = true;
    try {
      // Needs a valid access token, so this must run before the token is
      // cleared below. Push (de)registration failures must never block logout.
      await _unregisterPushToken();
      await _revokeRefreshToken();
      await _tokenStorage.clear();
    } finally {
      _isLoggingOut = false;
    }
    _session = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Best-effort `POST /Access/logout` so this device's refresh token can't
  /// be used again. Short timeout; any failure is only logged - the local
  /// sign-out always proceeds.
  Future<void> _revokeRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return;
      await _authService.logout(
        refreshToken,
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Logout request failed: $e');
    }
  }

  Future<void> _persistAndActivate(
    AuthResult tokens, {
    bool rememberMe = true,
  }) async {
    await _tokenStorage.saveTokens(
      tokens.accessToken,
      tokens.refreshToken,
      remember: rememberMe,
    );
    _activate(tokens.accessToken);
  }

  void _activate(String accessToken) {
    _session = AuthSession.fromAccessToken(accessToken);
    _setStatus(AuthStatus.authenticated);
    _registerPushToken();
    _applyThemePreference();
    _applyLanguagePreference();
  }

  /// [SessionManager] stored a new pair mid-session: re-decode the session so
  /// role/permission-driven UI (e.g. the admin sidebar) follows the new JWT.
  /// Ignored before sign-in - [bootstrap]/[login] activate the session
  /// themselves.
  void _handleTokensRefreshed(String accessToken) {
    if (_status != AuthStatus.authenticated) return;
    try {
      _session = AuthSession.fromAccessToken(accessToken);
      notifyListeners();
    } catch (e) {
      debugPrint('Refreshed access token could not be decoded: $e');
    }
  }

  /// [SessionManager] already cleared the tokens; this signs the UI out once
  /// (a burst of parallel 401s shares one refresh, so this runs once too).
  void _handleSessionExpired() {
    if (_isLoggingOut || _status != AuthStatus.authenticated) return;
    _session = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
    onSessionExpired?.call();
  }

  /// Fire-and-forget: fetches `UserPreference.Theme` and applies it to the
  /// shared [ThemeProvider]. Awaiting this would delay entering the app on a
  /// slow/unreachable backend, and a failure here must never block sign-in -
  /// it just leaves [ThemeProvider] at its current (light by default) mode.
  void _applyThemePreference() {
    unawaited(
      _preferencesService.getPreferences().then((preferences) {
        _themeProvider.setThemeMode(
          preferences.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        );
      }).catchError((e) {
        debugPrint('Failed to load theme preference: $e');
      }),
    );
  }

  /// Fire-and-forget: fetches `UserPreference.Language` and applies it to the
  /// shared [LocaleProvider]. Same reasoning as [_applyThemePreference] - must
  /// never block sign-in, and a failure just leaves [LocaleProvider] at its
  /// current (Bosnian by default) locale.
  void _applyLanguagePreference() {
    unawaited(
      _preferencesService.getPreferences().then((preferences) {
        _localeProvider.setLanguageCode(preferences.language);
      }).catchError((e) {
        debugPrint('Failed to load language preference: $e');
      }),
    );
  }

  /// Push (FCM) is mobile-only (Android/iOS) - no admin desktop UI for it, and
  /// it never runs during the brief web block before login. Same platform
  /// check as `PlatformGate.isDesktop`, duplicated here (rather than imported)
  /// to avoid a shared -> app dependency.
  static bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.linux;
  }

  /// Fire-and-forget: awaiting this would delay the authenticated screen from
  /// showing until the user responds to the OS permission prompt. Failures
  /// are logged, never surfaced to the user or allowed to affect auth state.
  void _registerPushToken() {
    if (!_isMobilePlatform) return;
    unawaited(
      _pushService.requestPermissionAndRegister().catchError((e) {
        debugPrint('Push token registration failed: $e');
      }),
    );
  }

  Future<void> _unregisterPushToken() async {
    if (!_isMobilePlatform) return;
    try {
      await _pushService.unregister();
    } catch (e) {
      debugPrint('Push token unregister failed: $e');
    }
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
    if (_sessionManager.onTokensRefreshed == _handleTokensRefreshed) {
      _sessionManager.onTokensRefreshed = null;
    }
    if (_sessionManager.onSessionExpired == _handleSessionExpired) {
      _sessionManager.onSessionExpired = null;
    }
    _authService.dispose();
    _pushService.dispose();
    _preferencesService.dispose();
    super.dispose();
  }
}
