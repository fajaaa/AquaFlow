import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_user.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_role_option.dart';
import 'package:aquaflow_desktop/admin/services/admin_user_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminUserService {
  AdminUserService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminUserPage> fetch({
    required int page,
    required int pageSize,
    String? name,
    int? userRoleId,
    bool? isActive,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    final nameText = name?.trim();
    if (nameText != null && nameText.isNotEmpty) {
      query['Name'] = nameText;
    }
    if (userRoleId != null) {
      query['UserRoleId'] = '$userRoleId';
    }
    if (isActive != null) {
      query['IsActive'] = '$isActive';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Users',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminUserException(
        _messageFor(response, 'Korisnike nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminUserException('Korisnici su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminUserException('Lista korisnika je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();

    return AdminUserPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AdminUser> create(AdminUserDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Users');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminUserException(
        _messageFor(response, 'Korisnika nije moguće dodati'),
      );
    }

    final user = _decodeUser(response.body);
    final profile = draft.profile;
    if (profile != null) {
      await _createCustomerProfile(user.id, profile);
    }
    return user;
  }

  /// [existingProfileId] must be the id of the user's current CustomerProfile
  /// (from [fetchCustomerProfile]), or null if they don't have one yet - this
  /// decides whether the profile is PATCHed or POSTed.
  Future<AdminUser> update(
    int id,
    AdminUserDraft draft, {
    int? existingProfileId,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Users/$id');

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminUserException(
        _messageFor(response, 'Korisnika nije moguće sačuvati'),
      );
    }

    final user = _decodeUser(response.body);
    final profile = draft.profile;
    if (profile != null) {
      if (existingProfileId != null) {
        await _updateCustomerProfile(existingProfileId, user.id, profile);
      } else {
        await _createCustomerProfile(user.id, profile);
      }
    }
    return user;
  }

  /// Fetches the CustomerProfile owned by [userId], or null if they don't
  /// have one (not a customer, or a customer with no profile yet).
  Future<AdminCustomerProfile?> fetchCustomerProfile(int userId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles').replace(
      queryParameters: {'UserId': '$userId', 'PageSize': '1'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminUserException(
        _messageFor(response, 'Profil korisnika nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List || itemsJson.isEmpty) return null;

    final first = itemsJson.first;
    if (first is! Map<String, dynamic>) return null;
    return AdminCustomerProfile.fromJson(first);
  }

  Future<void> _createCustomerProfile(
    int userId,
    AdminCustomerProfileDraft profile,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profile.toJson(userId)),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminUserException(
        _messageFor(response, 'Profil korisnika nije moguće sačuvati'),
      );
    }
  }

  Future<void> _updateCustomerProfile(
    int profileId,
    int userId,
    AdminCustomerProfileDraft profile,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles/$profileId');

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profile.toJson(userId)),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminUserException(
        _messageFor(response, 'Profil korisnika nije moguće sačuvati'),
      );
    }
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Users/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminUserException(
        _messageFor(response, 'Korisnika nije moguće obrisati'),
      );
    }
  }

  Future<List<AdminUserRoleOption>> fetchRoles() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/UserRoles').replace(
      queryParameters: {'PageSize': '100', 'IncludeTotalCount': 'true'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminUserException(
        _messageFor(response, 'Uloge nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminUserException('Uloge su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminUserException('Lista uloga je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminUserRoleOption.fromJson)
        .toList();
  }

  AdminUser _decodeUser(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminUserException('Korisnik je u neispravnom formatu.');
    }
    return AdminUser.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminUserException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminUserException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AdminUserException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminUserException('Greška mreže: ${e.message}');
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
