import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:aquaflow_collector/models/collector_fault_report.dart';
import 'package:aquaflow_collector/models/collector_fault_report_page.dart';
import 'package:aquaflow_collector/models/collector_fault_report_photo.dart';
import 'package:aquaflow_collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_collector/shared/config/api_config.dart';
import 'package:aquaflow_collector/shared/services/authenticated_client.dart';

/// Mobile collector data layer over `/FaultReports`, following the
/// `AdminFaultReportService` template. A collector no longer holds
/// `FaultReports.Manage`: the backend pins reads to reports assigned to the
/// caller's own `CollectorProfile` via `AssignedCollectorId` (same model as
/// `WaterMeterRequest`), and start/resolve are likewise allowed only for the
/// assigned collector - nothing extra is sent from here.
class CollectorFaultReportService {
  CollectorFaultReportService({
    http.Client? client,
    Duration? timeout,
  }) : _client = client ?? AuthenticatedClient.instance,
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  Future<CollectorFaultReportPage> fetch({
    required int page,
    required int pageSize,
    String? term,
    String? status,
  }) async {
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
      () => _client.get(uri),
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos',
    );

    final response = await _send(
      () => _client.get(uri),
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos/$photoId',
    );

    final response = await _send(
      () => _client.get(uri),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  /// `POST /FaultReports/{id}/start` (New -> InProgress). No body: the backend
  /// state machine owns the transition (clearing `resolvedAt`) and stamps the
  /// acting user from the JWT into `FaultStatusHistory`.
  Future<CollectorFaultReport> start(int id) => _postTransition(id, 'start');

  /// `POST /FaultReports/{id}/resolve` (New/InProgress -> Resolved). No body:
  /// the backend stamps `resolvedAt` itself - the FE no longer sends it.
  Future<CollectorFaultReport> resolve(int id) => _postTransition(id, 'resolve');

  /// One report assigned to the caller (`GET /FaultReports/{id}`) - used by
  /// the notification deep link. A report not assigned to this collector (or
  /// gone) is a 404 on the backend, surfacing as
  /// [CollectorFaultReportException].
  Future<CollectorFaultReport> fetchById(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports/$id');

    final response = await _send(
      () => _client.get(uri),
    );

    if (response.statusCode != 200) {
      throw CollectorFaultReportException(
        _messageFor(response, 'Prijavu kvara nije moguće učitati'),
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

  Future<CollectorFaultReport> _postTransition(int id, String action) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports/$id/$action');

    final response = await _send(
      () => _client.post(uri),
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
