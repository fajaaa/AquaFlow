import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_water_meter.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminWaterMeterService {
  AdminWaterMeterService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<AdminWaterMeter>> fetchForCustomer(int customerId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeters').replace(
      queryParameters: {
        'CustomerId': '$customerId',
        'PageSize': '100',
        'IncludeTotalCount': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminWaterMeterException(
        _messageFor(response, 'Vodomjere nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminWaterMeterException('Vodomjeri su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminWaterMeterException('Lista vodomjera je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminWaterMeter.fromJson)
        .toList();
  }

  /// Search-as-you-type lookup for the reading-route "add water meter"
  /// dialog: filters by serial number (Contains, case-sensitive collation on
  /// the backend) and/or settlement, bounded to [pageSize] results.
  Future<List<AdminWaterMeter>> search({
    String? serialNumber,
    int? settlementId,
    int pageSize = 20,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
    };

    final serialText = serialNumber?.trim();
    if (serialText != null && serialText.isNotEmpty) {
      query['SerialNumber'] = serialText;
    }
    if (settlementId != null) {
      query['SettlementId'] = '$settlementId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/WaterMeters',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminWaterMeterException(
        _messageFor(response, 'Vodomjere nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminWaterMeterException('Vodomjeri su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminWaterMeterException('Lista vodomjera je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminWaterMeter.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminWaterMeterException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminWaterMeterException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminWaterMeterException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminWaterMeterException('Greška mreže: ${e.message}');
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
