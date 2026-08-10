import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/account_details.dart';
import 'account_exception.dart';
import 'token_storage.dart';

/// Loads and saves the signed-in user's own account data (`/Account/me`). This
/// is the self-service endpoint any authenticated user can use regardless of
/// role, so - unlike editing users through `/Users` - it needs no admin
/// permission. The backend derives the user from the JWT, so no id is ever sent.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Network/HTTP failures throw [AccountException] with a user-safe message. The
/// base URL always comes from [ApiConfig.baseUrl] - the host is never hardcoded
/// here.
class AccountService {
  AccountService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// Fetches the caller's own account data via `GET /Account/me`.
  Future<AccountDetails> fetch() async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/me');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AccountException(
        _messageFor(response, 'Could not load your account'),
      );
    }

    return _parse(response, 'Account data are malformed.');
  }

  /// Saves [details] via `PUT /Account/me` and returns the updated data echoed
  /// back by the backend.
  Future<AccountDetails> update(AccountDetails details) async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/me');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(details.toUpdateJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw AccountException(
        _messageFor(response, 'Could not save your account'),
      );
    }

    return _parse(response, 'Account data are malformed.');
  }

  /// Changes the signed-in user's own password via `PUT /Account/me/password`.
  /// The backend rejects the call (400) if [currentPassword] does not match.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/me/password');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );

    if (response.statusCode != 204) {
      throw AccountException(
        _messageFor(response, 'Could not change your password'),
      );
    }
  }

  AccountDetails _parse(http.Response response, String malformedMessage) {
    // `/Account/me` returns a single UserResponse object (not a PageResult).
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AccountException(malformedMessage);
    }
    return AccountDetails.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AccountException('You are not signed in.');
    }
    return token;
  }

  /// Runs an HTTP call, mapping transport failures to a user-safe exception.
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AccountException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AccountException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw AccountException('Network error: ${e.message}');
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
