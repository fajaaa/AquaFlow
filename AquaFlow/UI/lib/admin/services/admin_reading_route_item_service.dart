import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_reading_route_item.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_item_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminReadingRouteItemService {
  AdminReadingRouteItemService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminReadingRouteItem> addItem(
    int readingRouteId,
    int waterMeterId,
    int sortOrder,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRouteItems');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'readingRouteId': readingRouteId,
          'waterMeterId': waterMeterId,
          'sortOrder': sortOrder,
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminReadingRouteItemException(
        _messageFor(response, 'Vodomjer nije moguće dodati na rutu'),
      );
    }

    return _decodeItem(response.body);
  }

  Future<void> removeItem(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRouteItems/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminReadingRouteItemException(
        _messageFor(response, 'Stavku nije moguće ukloniti'),
      );
    }
  }

  Future<AdminReadingRouteItem> reorder(int id, int sortOrder) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRouteItems/$id');

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'sortOrder': sortOrder}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteItemException(
        _messageFor(response, 'Redoslijed nije moguće sačuvati'),
      );
    }

    return _decodeItem(response.body);
  }

  AdminReadingRouteItem _decodeItem(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminReadingRouteItemException(
        'Stavka rute je u neispravnom formatu.',
      );
    }
    return AdminReadingRouteItem.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminReadingRouteItemException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminReadingRouteItemException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminReadingRouteItemException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminReadingRouteItemException('Greška mreže: ${e.message}');
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
