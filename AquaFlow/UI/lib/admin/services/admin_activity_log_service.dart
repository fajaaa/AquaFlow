import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_activity_log.dart';
import 'package:aquaflow_desktop/admin/models/admin_activity_log_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_activity_log_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Read-only data layer over `/ActivityLogs` (requires `ActivityLogs.Read`).
/// There are no write actions - rows are only ever created server-side via
/// `ActivityLogService.LogAsync`.
class AdminActivityLogService {
  AdminActivityLogService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminActivityLogPage> fetch({
    required int page,
    required int pageSize,
    int? userId,
    String? userEmail,
    String? eventType,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    if (userId != null) {
      query['UserId'] = '$userId';
    }
    final selectedUserEmail = userEmail?.trim();
    if (selectedUserEmail != null && selectedUserEmail.isNotEmpty) {
      query['UserEmail'] = selectedUserEmail;
    }
    final selectedEventType = eventType?.trim();
    if (selectedEventType != null && selectedEventType.isNotEmpty) {
      query['EventType'] = selectedEventType;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ActivityLogs',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminActivityLogException(
        _messageFor(response, 'Aktivnosti nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminActivityLogException(
        'Aktivnosti su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminActivityLogException('Lista aktivnosti je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminActivityLog.fromJson)
        .toList();

    return AdminActivityLogPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminActivityLogException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminActivityLogException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminActivityLogException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminActivityLogException('Greška mreže: ${e.message}');
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
