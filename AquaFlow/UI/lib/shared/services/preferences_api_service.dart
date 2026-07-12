import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_preferences.dart';
import 'preferences_exception.dart';
import 'token_storage.dart';

/// Loads and saves the signed-in user's own preferences (`/Account/preferences`).
/// Self-service, same trust model as `AccountService`/`/Account/me`: the
/// backend derives the user from the JWT, so no id is ever sent.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Network/HTTP failures throw [PreferencesException] with a user-safe
/// message. The base URL always comes from [ApiConfig.baseUrl] - the host is
/// never hardcoded here.
class PreferencesApiService {
  PreferencesApiService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// Fetches the caller's own preferences via `GET /Account/preferences`.
  Future<UserPreferences> getPreferences() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/preferences');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw PreferencesException(
        _messageFor(response, 'Could not load your preferences'),
      );
    }

    return _parse(response);
  }

  /// Saves [preferences] via `PUT /Account/preferences` and returns the
  /// updated data echoed back by the backend.
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/preferences');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(preferences.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw PreferencesException(
        _messageFor(response, 'Could not save your preferences'),
      );
    }

    return _parse(response);
  }

  UserPreferences _parse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const PreferencesException('Preferences data are malformed.');
    }
    return UserPreferences.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const PreferencesException('You are not signed in.');
    }
    return token;
  }

  /// Runs an HTTP call, mapping transport failures to a user-safe exception.
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw PreferencesException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const PreferencesException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw PreferencesException('Network error: ${e.message}');
    }
  }

  /// Builds an error message, preferring the backend's `{ message, errors }`
  /// body (e.g. validation failures) and falling back to the HTTP status.
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
