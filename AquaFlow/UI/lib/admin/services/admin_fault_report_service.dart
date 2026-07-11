import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_fault_report.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report_photo.dart';
import 'package:aquaflow_desktop/admin/services/admin_fault_report_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Desktop admin data layer over `/FaultReports`, following the
/// `AdminInvoiceService`/`AdminTariffService` template. `FaultReports.Manage`
/// (seeded onto Admin/Collector) lets a caller read every report and drive the
/// status transitions (`POST {id}/start`/`{id}/resolve`); there is no
/// admin-side create/delete for this resource.
class AdminFaultReportService {
  AdminFaultReportService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminFaultReportPage> fetch({
    required int page,
    required int pageSize,
    String? term,
    String? status,
    int? customerId,
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
    if (customerId != null) {
      query['CustomerId'] = '$customerId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminFaultReportException(
        _messageFor(response, 'Prijave kvarova nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminFaultReportException(
        'Prijave kvarova su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminFaultReportException(
        'Lista prijava kvarova je neispravna.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminFaultReport.fromJson)
        .toList();

    return AdminFaultReportPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Metadata for every photo attached to [faultReportId] (never raw bytes -
  /// see [fetchPhotoBytes]).
  Future<List<AdminFaultReportPhoto>> fetchPhotos(int faultReportId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminFaultReportException(
        _messageFor(response, 'Fotografije nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AdminFaultReportException(
        'Lista fotografija je u neispravnom formatu.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AdminFaultReportPhoto.fromJson)
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
      throw AdminFaultReportException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  /// `POST /FaultReports/{id}/start` (New -> InProgress). No body: the backend
  /// state machine owns the transition (clearing `resolvedAt`) and stamps the
  /// acting user from the JWT into `FaultStatusHistory`.
  Future<AdminFaultReport> start(int id) => _postTransition(id, 'start');

  /// `POST /FaultReports/{id}/resolve` (New/InProgress -> Resolved). No body:
  /// the backend stamps `resolvedAt` itself - the FE no longer sends it.
  Future<AdminFaultReport> resolve(int id) => _postTransition(id, 'resolve');

  Future<AdminFaultReport> _postTransition(int id, String action) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports/$id/$action');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminFaultReportException(
        _messageFor(response, 'Prijavu kvara nije moguće sačuvati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminFaultReportException(
        'Prijava kvara je u neispravnom formatu.',
      );
    }

    return AdminFaultReport.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminFaultReportException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminFaultReportException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminFaultReportException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminFaultReportException('Greška mreže: ${e.message}');
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
