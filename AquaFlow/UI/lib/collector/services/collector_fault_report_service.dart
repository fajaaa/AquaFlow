import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/collector/models/collector_fault_report.dart';
import 'package:aquaflow_desktop/collector/models/collector_fault_report_page.dart';
import 'package:aquaflow_desktop/collector/models/collector_fault_report_photo.dart';
import 'package:aquaflow_desktop/collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Mobile collector data layer over `/FaultReports`, following the
/// `AdminFaultReportService` template. `FaultReports.Manage` is seeded onto
/// both Admin and Collector (see `FaultReportsController`), so a collector
/// reads every report - there is no "assigned to me" pinning like
/// `WaterMeterRequest`, since `FaultReport` has no assignment concept.
class CollectorFaultReportService {
  CollectorFaultReportService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<CollectorFaultReportPage> fetch({
    required int page,
    required int pageSize,
    String? term,
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

    final termText = term?.trim();
    if (termText != null && termText.isNotEmpty) {
      query['Term'] = termText;
    }
    if (status != null && status.isNotEmpty) {
      query['Status'] = status;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Prijave kvarova nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorFaultReportException(
        'Prijave kvarova su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CollectorFaultReportException(
        'Lista prijava kvarova je neispravna.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CollectorFaultReport.fromJson)
        .toList();

    return CollectorFaultReportPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Metadata for every photo attached to [faultReportId] (never raw bytes -
  /// see [fetchPhotoBytes]).
  Future<List<CollectorFaultReportPhoto>> fetchPhotos(
    int faultReportId,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Fotografije nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const CollectorFaultReportException(
        'Lista fotografija je u neispravnom formatu.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CollectorFaultReportPhoto.fromJson)
        .toList();
  }

  /// Raw bytes of one photo (`GET /FaultReports/{id}/photos/{photoId}`), for
  /// `Image.memory` via the shared `AuthenticatedImage` widget.
  Future<Uint8List> fetchPhotoBytes(int faultReportId, int photoId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos/$photoId',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  /// `PATCH /FaultReports/{id}` with just `{ status }`, or `{ status,
  /// resolvedAt }` when transitioning to `Resolved` - the backend has no
  /// status/resolvedAt correlation logic of its own (`FaultReportPatchRequest`
  /// sets exactly the fields it is given), so the caller decides when to stamp
  /// `resolvedAt`.
  Future<CollectorFaultReport> updateStatus(
    int id,
    String status, {
    DateTime? resolvedAt,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports/$id');

    final body = <String, dynamic>{'status': status};
    if (resolvedAt != null) {
      body['resolvedAt'] = resolvedAt.toUtc().toIso8601String();
    }

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Prijavu kvara nije moguće sačuvati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CollectorFaultReportException(
        'Prijava kvara je u neispravnom formatu.',
      );
    }

    return CollectorFaultReport.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CollectorFaultReportException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CollectorFaultReportException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CollectorFaultReportException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CollectorFaultReportException('Greška mreže: ${e.message}');
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
