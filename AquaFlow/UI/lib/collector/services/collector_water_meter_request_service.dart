import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/models/collector_water_meter_request.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class CollectorWaterMeterRequestService {
  CollectorWaterMeterRequestService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<CollectorWaterMeterRequest>> fetchAssigned() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeterRequests').replace(
      queryParameters: {
        'PageSize': '100',
        'Status': 'Assigned',
        'SortBy': 'CreatedAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorWaterMeterRequestException(
        _messageFor(response, 'Zahtjeve nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorWaterMeterRequestException(
        'Zahtjevi su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CollectorWaterMeterRequestException(
        'Lista zahtjeva je neispravna.',
      );
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CollectorWaterMeterRequest.fromJson)
        .where((request) => request.isAssigned)
        .toList();
  }

  /// The backend forces only `CustomerId` from the request entity; the meter's
  /// `settlementId`/`street`/`houseNumber` come straight from this body - the
  /// collector's on-site (possibly corrected) address, which the register form
  /// prefills from the request's stored address
  /// (`WaterMeterRequestService.RegisterAsync`). It no longer derives the
  /// location from the customer's profile.
  Future<void> register({
    required int requestId,
    required String serialNumber,
    required DateTime installedAt,
    required double initialReading,
    required int settlementId,
    required String street,
    required String houseNumber,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/WaterMeterRequests/$requestId/register',
    );

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'serialNumber': serialNumber,
          'installedAt': installedAt.toUtc().toIso8601String(),
          'status': 'Active',
          'initialReading': initialReading,
          'lastReading': initialReading,
          'settlementId': settlementId,
          'street': street,
          'houseNumber': houseNumber,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw CollectorWaterMeterRequestException(
        _messageFor(response, 'Vodomjer nije moguće registrovati'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CollectorWaterMeterRequestException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CollectorWaterMeterRequestException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CollectorWaterMeterRequestException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CollectorWaterMeterRequestException('Greška mreže: ${e.message}');
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
