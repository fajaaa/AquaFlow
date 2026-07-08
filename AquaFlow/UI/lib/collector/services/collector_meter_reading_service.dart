import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Submits a collector-entered meter reading. Deliberately sends no
/// `CollectorId`/`PreviousReadingValue`/`ConsumptionM3`/`ReadingDate`/`Source`
/// - the server resolves/stamps all of those itself
/// (`MeterReadingCollectorEntryRequest`, `IMeterReadingService.CreateForCollectorAsync`).
/// `BillingCycleId` is omitted so the server resolves the single Open cycle.
class CollectorMeterReadingService {
  CollectorMeterReadingService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<void> submit({
    required int waterMeterId,
    required double readingValue,
    String? note,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/MeterReadings/collector-entry');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'waterMeterId': waterMeterId,
          'readingValue': readingValue,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw CollectorMeterReadingException(
        _messageFor(response, 'Očitanje nije moguće snimiti'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CollectorMeterReadingException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CollectorMeterReadingException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CollectorMeterReadingException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CollectorMeterReadingException('Greška mreže: ${e.message}');
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
