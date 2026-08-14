import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_collector/models/collector_meter_reading.dart';
import 'package:aquaflow_collector/models/collector_meter_reading_result.dart';
import 'package:aquaflow_collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_collector/shared/config/api_config.dart';
import 'package:aquaflow_collector/shared/services/token_storage.dart';

/// Submits a collector-entered meter reading. Deliberately sends no
/// `CollectorId`/`PreviousReadingValue`/`ConsumptionM3`/`ReadingDate`/`Source`
/// - the server resolves/stamps all of those itself
/// (`MeterReadingCollectorEntryRequest`, `IMeterReadingService.CreateForCollectorAsync`).
/// Also fetches the last reading of a meter to suggest a tariff and check
/// minimum spacing before the next reading.
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

  Future<CollectorMeterReadingResult> submit({
    required int waterMeterId,
    required double readingValue,
    required int tariffId,
    required String clientUuid,
    String? note,
    String? photoUrl,
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
          'tariffId': tariffId,
          'clientUuid': clientUuid,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (photoUrl != null && photoUrl.trim().isNotEmpty)
            'photoUrl': photoUrl.trim(),
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw CollectorMeterReadingException(
        _messageFor(response, 'Očitanje nije moguće snimiti'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorMeterReadingException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }
    return CollectorMeterReadingResult.fromJson(decoded);
  }

  /// Last reading of this meter that still counts towards billing — source of
  /// tariff suggestion and spacing check. Uses the dedicated
  /// `/MeterReadings/last-counting` route rather than the generic listing so a
  /// voided reading or one whose invoice was cancelled is never mistaken for
  /// the current last reading (which would otherwise block a new reading the
  /// server would actually accept).
  Future<CollectorMeterReading?> fetchLastReading(int waterMeterId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/MeterReadings/last-counting',
    ).replace(queryParameters: {'waterMeterId': '$waterMeterId'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorMeterReadingException(
        _messageFor(response, 'Zadnje očitanje nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return CollectorMeterReading.fromJson(decoded);
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
