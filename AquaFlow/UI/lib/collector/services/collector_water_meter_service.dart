import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/models/collector_water_meter.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Free-text water meter search for the collector search screen. `term` maps
/// to `WaterMeterSearchObject.Term`, an OR'd Contains match across serial
/// number, owner first/last name, settlement, street and house number
/// (`WaterMeterService.ApplyFilters`) - a Collector is not ownership-pinned
/// server-side (unlike a Customer), so this can return any meter.
class CollectorWaterMeterService {
  CollectorWaterMeterService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<CollectorWaterMeter>> search(String term) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeters').replace(
      queryParameters: {
        'Term': term,
        'PageSize': '50',
        'SortBy': 'SerialNumber',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorWaterMeterException(
        _messageFor(response, 'Vodomjere nije moguće pretražiti'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorWaterMeterException(
        'Vodomjeri su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CollectorWaterMeterException('Lista vodomjera je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CollectorWaterMeter.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CollectorWaterMeterException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CollectorWaterMeterException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CollectorWaterMeterException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CollectorWaterMeterException('Greška mreže: ${e.message}');
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
