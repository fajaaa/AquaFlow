import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/account_exception.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Backs the admin-only "Moj nalog" screen for everything beyond email/phone
/// (which already goes through the shared `AccountService`/`/Account/me`):
/// the signed-in admin's own CustomerProfile (name/language/theme) and a
/// password change. Kept separate from `AdminUserService` (which manages
/// *other* users through `/Users` and needs `Users.Manage`) since every call
/// here only ever acts on the caller's own id/profile.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Failures throw [AccountException] with a user-safe message. The base URL
/// always comes from [ApiConfig.baseUrl] - the host is never hardcoded here.
class AdminAccountService {
  AdminAccountService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// Fetches the CustomerProfile owned by [userId], or null if they don't have
  /// one yet (the common case for admins, who have no customer profile).
  Future<AdminCustomerProfile?> fetchProfile(int userId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles').replace(
      queryParameters: {'UserId': '$userId', 'PageSize': '1'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AccountException(
        _messageFor(response, 'Profil nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List || itemsJson.isEmpty) return null;

    final first = itemsJson.first;
    if (first is! Map<String, dynamic>) return null;
    return AdminCustomerProfile.fromJson(first);
  }

  /// Creates or updates the caller's own CustomerProfile. [existingProfileId]
  /// must be the id from [fetchProfile], or null to create a new one.
  Future<void> saveProfile(
    int userId,
    AdminCustomerProfileDraft draft, {
    int? existingProfileId,
  }) async {
    final token = await _requireToken();
    final isCreate = existingProfileId == null;
    final uri = isCreate
        ? Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles')
        : Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles/$existingProfileId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(draft.toJson(userId));

    final response = await _send(
      () => isCreate
          ? _client.post(uri, headers: headers, body: body)
          : _client.patch(uri, headers: headers, body: body),
    );

    final expectedStatus = isCreate ? 201 : 200;
    if (response.statusCode != expectedStatus) {
      throw AccountException(
        _messageFor(response, 'Profil nije moguće sačuvati'),
      );
    }
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
        _messageFor(response, 'Lozinku nije moguće promijeniti'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AccountException('Niste prijavljeni.');
    }
    return token;
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
