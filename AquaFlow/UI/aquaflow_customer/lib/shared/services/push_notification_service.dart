import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'push_notification_exception.dart';
import 'token_storage.dart';

/// Registers/unregisters this device's FCM token with the backend
/// (`POST /DeviceTokens/register|unregister`, see `DeviceTokensController`) and
/// keeps it fresh across token rotation. Mobile-only (Android/iOS) - callers
/// are responsible for the same platform gate used for Firebase init in
/// `main.dart` (`!kIsWeb && !PlatformGate.isDesktop`); this class assumes it is
/// only ever driven from a mobile build.
///
/// Follows the same `http.Client` + `TokenStorage` + timeout + dedicated
/// exception template as `NotificationService`/`AccountService`.
class PushNotificationService {
  PushNotificationService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  // Static: FirebaseMessaging.onTokenRefresh must only ever be listened to
  // once for the app's lifetime, but PushNotificationService instances are
  // short-lived (created fresh per call, like the other services), so the
  // subscription itself is kept at class level instead of instance level.
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Requests notification permission, registers the current FCM token with
  /// the backend, and (re-)subscribes to [FirebaseMessaging.onTokenRefresh] so
  /// a rotated token is re-registered automatically without the caller having
  /// to do anything else. Safe to call more than once (e.g. after both login
  /// and a later bootstrap) - a repeat call just replaces the subscription.
  Future<void> requestPermissionAndRegister() async {
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _register(token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(_register);
  }

  /// Unregisters the current device token (logout flow). Needs a valid access
  /// token, so callers must run this BEFORE clearing [TokenStorage].
  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final accessToken = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/DeviceTokens/unregister');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      ),
    );

    if (response.statusCode != 204) {
      throw PushNotificationException(
        _messageFor(response, 'Odjava push tokena nije uspjela'),
      );
    }
  }

  Future<void> _register(String token) async {
    // onTokenRefresh can fire while nobody is signed in (e.g. right after a
    // logout, before the app is closed) - silently skip rather than throwing.
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return;

    final uri = Uri.parse('${ApiConfig.baseUrl}/DeviceTokens/register');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token, 'platform': _platform}),
      ),
    );

    if (response.statusCode != 204) {
      throw PushNotificationException(
        _messageFor(response, 'Registracija push tokena nije uspjela'),
      );
    }
  }

  String get _platform => Platform.isAndroid ? 'android' : 'ios';

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const PushNotificationException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw PushNotificationException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const PushNotificationException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw PushNotificationException('Greška mreže: ${e.message}');
    }
  }

  String _messageFor(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Body was not JSON; fall through to the status-based message.
    }
    return '$fallback (HTTP ${response.statusCode}).';
  }

  void dispose() => _client.close();
}
