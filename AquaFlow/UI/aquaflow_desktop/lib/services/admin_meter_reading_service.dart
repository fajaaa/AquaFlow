import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/models/admin_meter_reading_page.dart';
import 'package:aquaflow_desktop/services/admin_meter_reading_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';
import 'package:aquaflow_desktop/models/admin_meter_reading.dart';

class AdminMeterReadingService {
  AdminMeterReadingService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminMeterReadingPage> fetchForWaterMeter({
    required int waterMeterId,
    required int page,
    required int pageSize,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'WaterMeterId': '$waterMeterId',
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'ReadingDate',
      'SortDescending': 'true',
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/MeterReadings',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminMeterReadingException(
        _messageFor(response, 'Očitanja nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminMeterReadingException('Očitanja su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminMeterReadingException('Lista očitanja je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminMeterReading.fromJson)
        .toList();

    return AdminMeterReadingPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<List<AdminCollectorProfile>> fetchCollectors() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CollectorProfiles').replace(
      queryParameters: {
        'PageSize': '100',
        'IncludeTotalCount': 'true',
        'SortBy': 'EmployeeCode',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminMeterReadingException(
        _messageFor(response, 'Inkasante nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminMeterReadingException('Inkasanti su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminMeterReadingException('Lista inkasanata je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCollectorProfile.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminMeterReadingException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminMeterReadingException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminMeterReadingException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminMeterReadingException('Greška mreže: ${e.message}');
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
