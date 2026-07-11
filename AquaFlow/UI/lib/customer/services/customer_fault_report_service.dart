import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;

import 'package:aquaflow_desktop/customer/models/customer_fault_report.dart';
import 'package:aquaflow_desktop/customer/models/customer_fault_report_page.dart';
import 'package:aquaflow_desktop/customer/models/customer_fault_report_photo.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Fault reports of the signed-in customer: list own, create a new one, and
/// manage its photos. No CustomerId/ReportedById/Status is ever sent on create
/// - the backend forces all of them from the JWT (see
/// `FaultReportsController.Create`), so this service can never create a report
/// under someone else's name. Follows the `CustomerWaterMeterRequestService`
/// template.
class CustomerFaultReportService {
  CustomerFaultReportService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// One page of the caller's fault reports, newest first. The backend pins
  /// `CustomerId` to the caller from the JWT, so this only ever returns the
  /// signed-in customer's own reports (every status).
  Future<CustomerFaultReportPage> fetchPage({
    required int page,
    int pageSize = 20,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'CreatedAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerFaultReportException(
        _messageFor(response, 'Prijave kvarova nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerFaultReportException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerFaultReportException(
        'Lista je u neispravnom formatu.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerFaultReport.fromJson)
        .toList();

    return CustomerFaultReportPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// `FaultReportInsertRequest` requires a `SettlementId` (no location-existence
  /// check on this path, see AGENTS.md) alongside `Title`/`Description`; the
  /// backend forces `CustomerId`/`ReportedById`/`Status`/`ResolvedAt` from the
  /// JWT for a self-service caller, so none of those are sent here.
  Future<CustomerFaultReport> create({
    required String title,
    required String description,
    required int settlementId,
    int? waterMeterId,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaultReports');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title.trim(),
          'description': description.trim(),
          'settlementId': settlementId,
          'waterMeterId': ?waterMeterId,
        }),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CustomerFaultReportException(
        _messageFor(response, 'Prijavu nije moguće poslati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerFaultReportException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerFaultReport.fromJson(decoded);
  }

  /// Metadata for every photo attached to [faultReportId] (never raw bytes -
  /// see `fetchPhotoBytes`). Same ownership gate as `fetchPage`/`create`.
  Future<List<CustomerFaultReportPhoto>> fetchPhotos(int faultReportId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerFaultReportException(
        _messageFor(response, 'Fotografije nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const CustomerFaultReportException(
        'Lista fotografija je u neispravnom formatu.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CustomerFaultReportPhoto.fromJson)
        .toList();
  }

  /// Uploads [imageFile] as a photo on [faultReportId]
  /// (`POST /FaultReports/{id}/photos`, multipart form field `file` - matches
  /// the `IFormFile file` parameter name on `FaultReportsController.UploadPhoto`).
  Future<CustomerFaultReportPhoto> uploadPhoto(
    int faultReportId,
    File imageFile,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos',
    );

    // `MultipartFile.fromPath` without an explicit contentType falls back to
    // application/octet-stream when the path has no/an unrecognized extension
    // (e.g. a cache file handed back by the Android Photo Picker) - the
    // backend's content-type whitelist then rejects it, so the type is
    // sniffed from the file's magic bytes (falling back to its extension,
    // then to image/jpeg - what the camera source always produces).
    final headerBytes = await imageFile.openRead(0, 12).first;
    final mimeType =
        lookupMimeType(imageFile.path, headerBytes: headerBytes) ??
        'image/jpeg';
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw CustomerFaultReportException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerFaultReportException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerFaultReportException('Greška mreže: ${e.message}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CustomerFaultReportException(
        _messageFor(response, 'Fotografiju nije moguće poslati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerFaultReportException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerFaultReportPhoto.fromJson(decoded);
  }

  /// Raw bytes of one photo (`GET /FaultReports/{id}/photos/{photoId}`), for
  /// `Image.memory` via the shared `AuthenticatedImage` widget - no endpoint in
  /// this app serves images without a Bearer token, so there is no plain URL to
  /// hand to `Image.network`.
  Future<Uint8List> fetchPhotoBytes(int faultReportId, int photoId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/FaultReports/$faultReportId/photos/$photoId',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerFaultReportException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CustomerFaultReportException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerFaultReportException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerFaultReportException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerFaultReportException('Greška mreže: ${e.message}');
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
