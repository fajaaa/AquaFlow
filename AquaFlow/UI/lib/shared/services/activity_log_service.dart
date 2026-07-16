import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/activity_log_item.dart';
import '../models/activity_log_page.dart';
import 'activity_log_exception.dart';
import 'token_storage.dart';

class ActivityLogService {
  ActivityLogService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<ActivityLogPage> fetchMine({
    required int page,
    required int pageSize,
  }) async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/ActivityLogs/mine').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'CreatedAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw ActivityLogException(
        _messageFor(response, 'Aktivnosti nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ActivityLogException('Aktivnosti su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const ActivityLogException('Lista aktivnosti je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(ActivityLogItem.fromJson)
        .toList();

    return ActivityLogPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const ActivityLogException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw ActivityLogException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const ActivityLogException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw ActivityLogException('Greška mreže: ${e.message}');
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
