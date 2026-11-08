import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/admin_role.dart';
import 'package:aquaflow_desktop/services/admin_role_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/authenticated_client.dart';

/// Roles, permissions and role-permission assignments (all behind Roles.Manage).
class AdminRoleService {
  AdminRoleService({http.Client? client, Duration? timeout})
    : _client = client ?? AuthenticatedClient.instance,
      _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  // ---- Roles ----

  Future<AdminPage<AdminRole>> fetchRoles({
    required int page,
    required int pageSize,
    String? name,
  }) {
    final query = _pageQuery(page, pageSize, 'Name');
    _putText(query, 'Name', name);
    return _fetchPage('UserRoles', query, AdminRole.fromJson);
  }

  Future<void> createRole(AdminRoleDraft draft) => _write(
    'UserRoles',
    'POST',
    draft.toJson(),
    201,
    'Rolu nije moguće dodati',
  );

  Future<void> updateRole(int id, AdminRoleDraft draft) => _write(
    'UserRoles/$id',
    'PUT',
    draft.toJson(),
    200,
    'Rolu nije moguće sačuvati',
  );

  Future<void> deleteRole(int id) =>
      _write('UserRoles/$id', 'DELETE', null, 204, 'Rolu nije moguće obrisati');

  // ---- Permissions ----

  Future<AdminPage<AdminPermission>> fetchPermissions({
    required int page,
    required int pageSize,
    String? code,
    String? name,
    String? module,
  }) {
    final query = _pageQuery(page, pageSize, 'Module');
    _putText(query, 'Code', code);
    _putText(query, 'Name', name);
    _putText(query, 'Module', module);
    return _fetchPage('Permissions', query, AdminPermission.fromJson);
  }

  /// Every permission (the API caps a page at 100), ordered by module.
  Future<List<AdminPermission>> fetchAllPermissions() async {
    const pageSize = 100;
    final all = <AdminPermission>[];
    for (var page = 1; ; page++) {
      final result = await fetchPermissions(page: page, pageSize: pageSize);
      all.addAll(result.items);
      if (result.items.length < pageSize || all.length >= result.totalCount) {
        return all;
      }
    }
  }

  Future<void> createPermission(AdminPermissionDraft draft) => _write(
    'Permissions',
    'POST',
    draft.toJson(),
    201,
    'Dozvolu nije moguće dodati',
  );

  Future<void> updatePermission(int id, AdminPermissionDraft draft) => _write(
    'Permissions/$id',
    'PUT',
    draft.toJson(),
    200,
    'Dozvolu nije moguće sačuvati',
  );

  Future<void> deletePermission(int id) => _write(
    'Permissions/$id',
    'DELETE',
    null,
    204,
    'Dozvolu nije moguće obrisati',
  );

  // ---- Role permissions ----

  Future<List<AdminRolePermission>> fetchRolePermissions(int roleId) async {
    final query = _pageQuery(1, 100, 'Id')..['UserRoleId'] = '$roleId';
    final result = await _fetchPage(
      'UserRolePermissions',
      query,
      AdminRolePermission.fromJson,
    );
    return result.items;
  }

  Future<AdminRolePermission> assign(int roleId, int permissionId) async {
    final response = await _send(
      () => _client.post(
        _uri('UserRolePermissions'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'userRoleId': roleId, 'permissionId': permissionId}),
      ),
    );
    if (response.statusCode != 201) {
      throw AdminRoleException(
        _messageFor(response, 'Dozvolu nije moguće dodijeliti'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminRoleException('Dodjela je u neispravnom formatu.');
    }
    return AdminRolePermission.fromJson(decoded);
  }

  Future<void> unassign(int assignmentId) => _write(
    'UserRolePermissions/$assignmentId',
    'DELETE',
    null,
    204,
    'Dozvolu nije moguće ukloniti',
  );

  // ---- Helpers ----

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/$path').replace(queryParameters: query);

  Map<String, String> _pageQuery(int page, int pageSize, String sortBy) => {
    'Page': '$page',
    'PageSize': '$pageSize',
    'IncludeTotalCount': 'true',
    'SortBy': sortBy,
    'SortDescending': 'false',
  };

  void _putText(Map<String, String> query, String key, String? value) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) query[key] = text;
  }

  Future<AdminPage<T>> _fetchPage<T>(
    String path,
    Map<String, String> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _send(() => _client.get(_uri(path, query)));
    if (response.statusCode != 200) {
      throw AdminRoleException(
        _messageFor(response, 'Podatke nije moguće učitati'),
      );
    }
    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (decoded is! Map<String, dynamic> || itemsJson is! List) {
      throw const AdminRoleException('Podaci su u neispravnom formatu.');
    }
    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList();
    return AdminPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<void> _write(
    String path,
    String method,
    Map<String, Object?>? body,
    int expectedStatus,
    String fallback,
  ) async {
    final uri = _uri(path);
    const headers = {'Content-Type': 'application/json'};
    final response = await _send(() {
      switch (method) {
        case 'POST':
          return _client.post(uri, headers: headers, body: jsonEncode(body));
        case 'PUT':
          return _client.put(uri, headers: headers, body: jsonEncode(body));
        default:
          return _client.delete(uri);
      }
    });
    if (response.statusCode != expectedStatus) {
      throw AdminRoleException(_messageFor(response, fallback));
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminRoleException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AdminRoleException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminRoleException('Greška mreže: ${e.message}');
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
