import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter_request.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter_request_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminWaterMeterRequestService {
  AdminWaterMeterRequestService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminWaterMeterRequestPage> fetch({
    required int page,
    required int pageSize,
    String? status,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    final selectedStatus = status?.trim();
    if (selectedStatus != null && selectedStatus.isNotEmpty) {
      query['Status'] = selectedStatus;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/WaterMeterRequests',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminWaterMeterRequestException(
        _messageFor(response, 'Zahtjeve nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminWaterMeterRequestException(
        'Zahtjevi su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminWaterMeterRequestException(
        'Lista zahtjeva je neispravna.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminWaterMeterRequest.fromJson)
        .toList();

    return AdminWaterMeterRequestPage(
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
      throw AdminWaterMeterRequestException(
        _messageFor(response, 'Collectore nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminWaterMeterRequestException(
        'Collectori su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminWaterMeterRequestException(
        'Lista collectora je neispravna.',
      );
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCollectorProfile.fromJson)
        .toList();
  }

  Future<void> assign(int id, int collectorId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeterRequests/$id/assign');

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
      throw AdminWaterMeterRequestException(
        _messageFor(response, 'Zahtjev nije moguće dodijeliti'),
      );
    }
  }

  Future<void> reject(int id, String? reason) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeterRequests/$id/reject');
    final reasonText = reason?.trim();

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (reasonText != null && reasonText.isNotEmpty) 'reason': reasonText,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminWaterMeterRequestException(
        _messageFor(response, 'Zahtjev nije moguće odbiti'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminWaterMeterRequestException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminWaterMeterRequestException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminWaterMeterRequestException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminWaterMeterRequestException('Greška mreže: ${e.message}');
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
