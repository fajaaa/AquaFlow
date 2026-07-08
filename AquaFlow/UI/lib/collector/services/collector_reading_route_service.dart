import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/models/collector_reading_route.dart';
import 'package:aquaflow_desktop/collector/models/collector_reading_route_item.dart';
import 'package:aquaflow_desktop/collector/services/collector_reading_route_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class CollectorReadingRouteService {
  CollectorReadingRouteService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// The backend pins `GET /ReadingRoutes` to the caller's own
  /// `CollectorProfile.Id` for the Collector role
  /// (`ReadingRoutesController.GetAll`), so this always returns only the
  /// signed-in collector's own routes regardless of query filters.
  Future<List<CollectorReadingRoute>> fetchMine() async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ReadingRoutes',
    ).replace(queryParameters: {'PageSize': '100', 'SortBy': 'ScheduledDate'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorReadingRouteException(
        _messageFor(response, 'Rute nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorReadingRouteException(
        'Rute su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CollectorReadingRouteException('Lista ruta je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CollectorReadingRoute.fromJson)
        .toList();
  }

  /// Same ownership pinning as `fetchMine` - `ReadingRoutesController.GetItems`
  /// 404s if the route doesn't belong to the caller's `CollectorProfile`.
  Future<List<CollectorReadingRouteItem>> fetchItems(int routeId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ReadingRoutes/$routeId/items');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorReadingRouteException(
        _messageFor(response, 'Vodomjere rute nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const CollectorReadingRouteException(
        'Lista vodomjera rute je neispravna.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CollectorReadingRouteItem.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CollectorReadingRouteException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CollectorReadingRouteException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CollectorReadingRouteException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CollectorReadingRouteException('Greška mreže: ${e.message}');
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
