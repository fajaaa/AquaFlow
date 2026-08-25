import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/models/admin_collector_profile_draft.dart';
import 'package:aquaflow_desktop/models/admin_collector_profile_page.dart';
import 'package:aquaflow_desktop/models/admin_user.dart';
import 'package:aquaflow_desktop/models/admin_user_role_option.dart';
import 'package:aquaflow_desktop/services/admin_collector_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminCollectorService {
  AdminCollectorService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminCollectorProfilePage> fetch({
    required int page,
    required int pageSize,
  }) {
    return fetchCollectors(page: page, pageSize: pageSize);
  }

  Future<AdminCollectorProfilePage> fetchCollectors({
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CollectorProfiles').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'EmployeeCode',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Inkasante nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCollectorException(
        'Inkasanti su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminCollectorException('Lista inkasanata je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCollectorProfile.fromJson)
        .toList();

    return AdminCollectorProfilePage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AdminCollectorProfile?> fetchCollectorProfile(int userId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/CollectorProfiles',
    ).replace(queryParameters: {'UserId': '$userId', 'PageSize': '1'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Profil inkasanta nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List || itemsJson.isEmpty) return null;

    final first = itemsJson.first;
    if (first is! Map<String, dynamic>) return null;
    return AdminCollectorProfile.fromJson(first);
  }

  /// Fetches the CustomerProfile owned by [userId] (collectors reuse the
  /// same profile table as customers), or null if they don't have one yet.
  Future<AdminCustomerProfile?> fetchCustomerProfile(int userId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles').replace(
      queryParameters: {'UserId': '$userId', 'PageSize': '1'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Profil inkasanta nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List || itemsJson.isEmpty) return null;

    final first = itemsJson.first;
    if (first is! Map<String, dynamic>) return null;
    return AdminCustomerProfile.fromJson(first);
  }

  Future<AdminCollectorProfile> create(AdminCollectorProfileDraft draft) {
    return createCollectorProfile(draft.userId);
  }

  Future<AdminCollectorProfile> createCollectorProfile(int userId) async {
    final token = await _requireToken();
    return _postCollectorProfile(token, AdminCollectorProfileDraft(userId: userId));
  }

  /// Saves an edit of an existing collector: patches the collector's own
  /// [User] record (email/phone/status/optional password) and upserts their
  /// CustomerProfile (name) - mirroring how the Korisnici screen edits a
  /// user in one flow.
  ///
  /// [existingProfileId] must be the id of the collector's current
  /// CustomerProfile (from [fetchCustomerProfile]), or null if they don't
  /// have one yet - this decides whether the profile is PATCHed or POSTed.
  Future<AdminCollectorProfile> updateCollectorUserAndProfile({
    required int collectorProfileId,
    required int userId,
    required String email,
    required String phone,
    required bool isActive,
    String? password,
    required String firstName,
    required String lastName,
    int? existingProfileId,
  }) async {
    final token = await _requireToken();

    await _patchCollectorUser(
      token,
      userId,
      email: email,
      phone: phone,
      isActive: isActive,
      password: password,
    );

    final profile = AdminCustomerProfileDraft(
      firstName: firstName,
      lastName: lastName,
      theme: 'light',
    );
    if (existingProfileId != null) {
      await _patchCustomerProfile(token, existingProfileId, userId, profile);
    } else {
      await _postCustomerProfile(token, userId, profile);
    }

    return _fetchCollectorProfileById(token, collectorProfileId);
  }

  Future<AdminCollectorProfile> _fetchCollectorProfileById(
    String token,
    int id,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/CollectorProfiles/$id');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Profil inkasanta nije moguće učitati'),
      );
    }

    return _decodeCollector(response.body);
  }

  Future<void> _patchCollectorUser(
    String token,
    int userId, {
    required String email,
    required String phone,
    required bool isActive,
    String? password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Users/$userId');

    final body = <String, Object?>{
      'email': email,
      'phone': phone,
      'isActive': isActive,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Korisnika inkasanta nije moguće sačuvati'),
      );
    }
  }

  Future<void> _patchCustomerProfile(
    String token,
    int profileId,
    int userId,
    AdminCustomerProfileDraft profile,
  ) async {
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
      throw AdminCollectorException(
        _messageFor(response, 'Profil inkasanta nije moguće sačuvati'),
      );
    }
  }

  Future<AdminCollectorProfile> createCollectorUserWithProfile({
    required String email,
    required String password,
    String phone = '',
    String? firstName,
    String? lastName,
    bool isActive = true,
    String theme = 'light',
  }) async {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final hasProfileInput = first.isNotEmpty || last.isNotEmpty;
    if (hasProfileInput && (first.isEmpty || last.isEmpty)) {
      throw const AdminCollectorException(
        'Ime i prezime su obavezni ako unosite profil inkasanta.',
      );
    }

    final token = await _requireToken();
    final collectorRoleId = await _fetchCollectorRoleId(token);
    final user = await _postCollectorUser(
      token,
      email: email.trim(),
      password: password.trim(),
      phone: phone.trim(),
      userRoleId: collectorRoleId,
      isActive: isActive,
    );

    if (hasProfileInput) {
      await _postCustomerProfile(
        token,
        user.id,
        AdminCustomerProfileDraft(
          firstName: first,
          lastName: last,
          theme: theme,
        ),
      );
    }

    return _postCollectorProfile(token, AdminCollectorProfileDraft(userId: user.id));
  }

  Future<int> _fetchCollectorRoleId(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/UserRoles').replace(
      queryParameters: {
        'Name': 'Collector',
        'IsActive': 'true',
        'PageSize': '20',
        'IncludeTotalCount': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCollectorException(
        _messageFor(response, 'Rolu Collector nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCollectorException('Role su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminCollectorException('Lista rola je neispravna.');
    }

    for (final roleJson in itemsJson.whereType<Map<String, dynamic>>()) {
      final role = AdminUserRoleOption.fromJson(roleJson);
      if (role.name.toLowerCase() == 'collector') {
        return role.id;
      }
    }

    throw const AdminCollectorException('Rola Collector nije pronađena.');
  }

  Future<AdminUser> _postCollectorUser(
    String token, {
    required String email,
    required String password,
    required String phone,
    required int userRoleId,
    required bool isActive,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Users');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'phone': phone,
          'userRoleId': userRoleId,
          'isActive': isActive,
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminCollectorException(
        _messageFor(response, 'Korisnika inkasanta nije moguće dodati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCollectorException(
        'Korisnik inkasant je u neispravnom formatu.',
      );
    }

    return AdminUser.fromJson(decoded);
  }

  Future<void> _postCustomerProfile(
    String token,
    int userId,
    AdminCustomerProfileDraft profile,
  ) async {
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
      throw AdminCollectorException(
        _messageFor(response, 'Profil korisnika nije moguće sačuvati'),
      );
    }
  }

  Future<AdminCollectorProfile> _postCollectorProfile(
    String token,
    AdminCollectorProfileDraft draft,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/CollectorProfiles');

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
      throw AdminCollectorException(
        _messageFor(response, 'Inkasant nije moguće dodati'),
      );
    }

    return _decodeCollector(response.body);
  }

  AdminCollectorProfile _decodeCollector(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCollectorException(
        'Profil inkasanta je u neispravnom formatu.',
      );
    }
    return AdminCollectorProfile.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminCollectorException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminCollectorException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminCollectorException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminCollectorException('Greška mreže: ${e.message}');
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
