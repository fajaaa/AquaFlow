import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/models/collector_billing_cycle.dart';
import 'package:aquaflow_desktop/collector/models/collector_meter_reading_result.dart';
import 'package:aquaflow_desktop/collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Submits a collector-entered meter reading, and looks up the current
/// billing period so the entry screen can show it and detect an
/// already-recorded reading before the collector fills in the form.
/// Deliberately sends no
/// `CollectorId`/`PreviousReadingValue`/`ConsumptionM3`/`ReadingDate`/`Source`
/// - the server resolves/stamps all of those itself
/// (`MeterReadingCollectorEntryRequest`, `IMeterReadingService.CreateForCollectorAsync`).
/// `BillingCycleId` is omitted on submit so the server resolves the single
/// Open cycle - the lookup here is purely informational, the server is the
/// source of truth for which cycle a reading actually lands in.
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

  /// The current Open billing period, or null when there is none (or more
  /// than one - an ambiguous case the actual submit call will reject with its
  /// own clear error, so this lookup just falls back to "unknown period"
  /// rather than guessing).
  Future<CollectorBillingCycle?> fetchCurrentCycle() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/BillingCycles').replace(
      queryParameters: {
        'Status': 'Open',
        'PageSize': '2',
        'IncludeTotalCount': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorMeterReadingException(
        _messageFor(response, 'Tekući period nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List || itemsJson.length != 1) {
      return null;
    }
    return CollectorBillingCycle.fromJson(
      itemsJson.single as Map<String, dynamic>,
    );
  }

  /// Whether `waterMeterId` already has a reading recorded for
  /// `billingCycleId`, so the entry screen can show this upfront instead of
  /// only after a failed submit.
  Future<bool> hasReadingForCycle({
    required int waterMeterId,
    required int billingCycleId,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/MeterReadings').replace(
      queryParameters: {
        'WaterMeterId': '$waterMeterId',
        'BillingCycleId': '$billingCycleId',
        'PageSize': '1',
        'IncludeTotalCount': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorMeterReadingException(
        _messageFor(response, 'Status očitanja nije moguće provjeriti'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return false;
    final totalCount = decoded['totalCount'];
    return totalCount is num && totalCount > 0;
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
