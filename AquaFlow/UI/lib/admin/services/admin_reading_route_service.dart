import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_reading_route.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_item.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminReadingRouteService {
  AdminReadingRouteService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminReadingRoutePage> fetch({
    required int page,
    required int pageSize,
    String? name,
    String? status,
    int? collectorId,
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
    final statusText = status?.trim();
    if (statusText != null && statusText.isNotEmpty) {
      query['Status'] = statusText;
    }
    if (collectorId != null) {
      query['CollectorId'] = '$collectorId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ReadingRoutes',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Rute nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminReadingRouteException('Rute su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminReadingRouteException('Lista ruta je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminReadingRoute.fromJson)
        .toList();

    return AdminReadingRoutePage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AdminReadingRoute> create(AdminReadingRouteDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes');

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
      throw AdminReadingRouteException(
        _messageFor(response, 'Rutu nije moguće dodati'),
      );
    }

    return _decodeRoute(response.body);
  }

  Future<AdminReadingRoute> update(int id, AdminReadingRouteDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$id');

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
      throw AdminReadingRouteException(
        _messageFor(response, 'Rutu nije moguće sačuvati'),
      );
    }

    return _decodeRoute(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Rutu nije moguće obrisati'),
      );
    }
  }

  Future<void> assign(int id, int collectorId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$id/assign');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'collectorId': collectorId}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Rutu nije moguće dodijeliti'),
      );
    }
  }

  Future<void> cancel(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$id/cancel');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Rutu nije moguće otkazati'),
      );
    }
  }

  Future<List<AdminReadingRouteItem>> fetchItems(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$id/items');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Stavke rute nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AdminReadingRouteException(
        'Lista stavki rute je neispravna.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AdminReadingRouteItem.fromJson)
        .toList();
  }

  Future<List<AdminReadingRouteItem>> bulkAddBySettlement(
    int id,
    int settlementId,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ReadingRoutes/$id/items/bulk-by-settlement',
    );

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'settlementId': settlementId}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminReadingRouteException(
        _messageFor(response, 'Vodomjere nije moguće dodati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AdminReadingRouteException(
        'Lista dodanih stavki je neispravna.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AdminReadingRouteItem.fromJson)
        .toList();
  }

  AdminReadingRoute _decodeRoute(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminReadingRouteException('Ruta je u neispravnom formatu.');
    }
    return AdminReadingRoute.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminReadingRouteException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminReadingRouteException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminReadingRouteException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminReadingRouteException('Greška mreže: ${e.message}');
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
