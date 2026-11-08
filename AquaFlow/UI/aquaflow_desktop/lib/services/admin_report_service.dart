import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/services/admin_report_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/authenticated_client.dart';

/// Downloads the backend's PDF reports from `GET /Reports/*/pdf`.
class AdminReportService {
  AdminReportService({http.Client? client, Duration? timeout})
    : _client = client ?? AuthenticatedClient.instance,
      _timeout = timeout ?? const Duration(seconds: 60);

  final http.Client _client;
  final Duration _timeout;

  Future<Uint8List> fetchConsumptionPdf(
    DateTime from,
    DateTime to,
    int? cityId,
  ) => _fetch('consumption', from, to, cityId);

  Future<Uint8List> fetchBillingPdf(DateTime from, DateTime to, int? cityId) =>
      _fetch('billing', from, to, cityId);

  Future<Uint8List> _fetch(
    String report,
    DateTime from,
    DateTime to,
    int? cityId,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Reports/$report/pdf').replace(
      queryParameters: {
        'from': _dateParam(from),
        'to': _dateParam(to),
        if (cityId != null) 'cityId': '$cityId',
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on SocketException {
      throw AdminReportException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminReportException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminReportException('Greška mreže: ${e.message}');
    }

    if (response.statusCode == 403) {
      throw const AdminReportException(
        'Nemate pravo pristupa izvještajima. Odjavite se i prijavite ponovo.',
      );
    }
    if (response.statusCode != 200) {
      throw AdminReportException(
        _messageFor(response, 'Izvještaj nije moguće preuzeti'),
      );
    }
    return response.bodyBytes;
  }

  String _dateParam(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }

  String _messageFor(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
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
