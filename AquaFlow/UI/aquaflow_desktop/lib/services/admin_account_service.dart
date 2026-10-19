import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/account_exception.dart';
import 'package:aquaflow_desktop/shared/services/authenticated_client.dart';

/// Backs the admin-only "Moj nalog" screen for the one thing that doesn't go
/// through the shared `AccountService`/`/Account/me`: a password change.
/// Kept separate from `AdminUserService` (which manages *other* users through
/// `/Users` and needs `Users.Manage`) since this only ever acts on the
/// caller's own password.
///
/// The bearer token is attached (and refreshed) by [AuthenticatedClient].
/// Failures throw [AccountException] with a user-safe message. The base URL
/// always comes from [ApiConfig.baseUrl] - the host is never hardcoded here.
class AdminAccountService {
  AdminAccountService({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? AuthenticatedClient.instance,
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  /// Changes the signed-in user's own password via `PUT /Account/me/password`.
  /// The backend rejects the call (400) if [currentPassword] does not match.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Account/me/password');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
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
        _messageFor(response, 'Lozinku nije moguće promijeniti'),
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AccountException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AccountException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AccountException('Greška mreže: ${e.message}');
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
