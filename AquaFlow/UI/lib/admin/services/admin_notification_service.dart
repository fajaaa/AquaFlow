import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_notification_draft.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/models/app_notification.dart';
import 'package:aquaflow_desktop/shared/models/app_notification_page.dart';
import 'package:aquaflow_desktop/shared/services/notification_exception.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminNotificationService {
  AdminNotificationService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AppNotificationPage> fetch({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    String? audience,
    int? settlementId,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    final searchText = search?.trim();
    if (searchText != null && searchText.isNotEmpty) {
      query['Search'] = searchText;
    }
    final selectedType = type?.trim();
    if (selectedType != null && selectedType.isNotEmpty) {
      query['Type'] = selectedType;
    }
    final selectedAudience = audience?.trim();
    if (selectedAudience != null && selectedAudience.isNotEmpty) {
      query['Audience'] = selectedAudience;
    }
    if (settlementId != null) {
      query['SettlementId'] = '$settlementId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Notifications',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(response, 'Obavijesti nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const NotificationException('Obavijesti su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const NotificationException('Lista obavijesti je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();

    return AppNotificationPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AppNotification> create(AdminNotificationDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notifications');

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
      throw NotificationException(
        _messageFor(response, 'Obavijest nije moguće dodati'),
      );
    }

    return _decodeNotification(response.body);
  }

  Future<AppNotification> update(int id, AdminNotificationDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notifications/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(response, 'Obavijest nije moguće sačuvati'),
      );
    }

    return _decodeNotification(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notifications/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw NotificationException(
        _messageFor(response, 'Obavijest nije moguće obrisati'),
      );
    }
  }

  AppNotification _decodeNotification(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const NotificationException('Obavijest je u neispravnom formatu.');
    }
    return AppNotification.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const NotificationException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw NotificationException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const NotificationException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw NotificationException('Greška mreže: ${e.message}');
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
