import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/admin_recommendation.dart';
import 'package:aquaflow_desktop/models/admin_recommendation_page.dart';
import 'package:aquaflow_desktop/services/admin_recommendation_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminRecommendationService {
  AdminRecommendationService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminRecommendationPage> fetch({
    required int page,
    required int pageSize,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Recommendations').replace(
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
      throw AdminRecommendationException(
        _messageFor(response, 'Preporuke nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminRecommendationException(
        'Preporuke su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminRecommendationException(
        'Lista preporuka je neispravna.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminRecommendation.fromJson)
        .toList();

    return AdminRecommendationPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<void> recompute() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Recommendations/recompute');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminRecommendationException(
        _messageFor(response, 'Preporuke nije moguće osvježiti'),
      );
    }
  }

  Future<void> markAsRead(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Recommendations/$id');

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isRead': true}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminRecommendationException(
        _messageFor(response, 'Preporuku nije moguće označiti kao pročitanu'),
      );
    }
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Recommendations/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminRecommendationException(
        _messageFor(response, 'Preporuku nije moguće obrisati'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminRecommendationException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminRecommendationException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminRecommendationException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminRecommendationException('Greška mreže: ${e.message}');
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
