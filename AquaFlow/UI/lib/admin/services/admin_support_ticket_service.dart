import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;

import 'package:aquaflow_desktop/admin/models/admin_support_ticket.dart';
import 'package:aquaflow_desktop/admin/models/admin_support_ticket_message.dart';
import 'package:aquaflow_desktop/admin/models/admin_support_ticket_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_support_ticket_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Desktop admin data layer over `/SupportTickets`, following the
/// `AdminFaultReportService` template for the read/transition routes and
/// `CustomerSupportTicketService` for the multipart reply. `SupportTickets.Manage`
/// (seeded onto Admin) lets a caller read every ticket (`fetch`/`fetchById`),
/// reply on any thread (`addMessage`, stored as a staff message - the backend
/// derives `IsFromStaff` from the caller's permission, never the request) and
/// close/reopen it; there is no admin-side create/delete for this resource
/// (tickets are opened by customers).
class AdminSupportTicketService {
  AdminSupportTicketService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// One page of every ticket (`GET /SupportTickets`, requires
  /// `SupportTickets.Manage`), sorted by `LastMessageAt` descending (the
  /// backend default, sent explicitly here) with optional `Status`/`Term`
  /// (subject) filters.
  Future<AdminSupportTicketPage> fetch({
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
      'SortBy': 'LastMessageAt',
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
      '${ApiConfig.baseUrl}/SupportTickets',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSupportTicketException(
        _messageFor(response, 'Tikete nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminSupportTicketException(
        'Lista tiketa je u neispravnom formatu.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminSupportTicket.fromJson)
        .toList();

    return AdminSupportTicketPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// The full thread of one ticket (`GET /SupportTickets/{id}`): header
  /// fields plus every message and its photo metadata.
  Future<AdminSupportTicket> fetchById(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/SupportTickets/$id');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSupportTicketException(
        _messageFor(response, 'Tiket nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return AdminSupportTicket.fromJson(decoded);
  }

  /// Appends a staff reply (with optional photos) to [ticketId]
  /// (`POST /SupportTickets/{id}/messages`, multipart form field `body` +
  /// `IFormFileCollection files`). `IsFromStaff` is derived server-side from
  /// the caller's `SupportTickets.Manage` permission, so this always lands as
  /// a staff message. The backend rejects a reply to a Closed ticket (-> 400).
  Future<AdminSupportTicketMessage> addMessage(
    int ticketId, {
    required String body,
    List<File> images = const [],
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/SupportTickets/$ticketId/messages',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['body'] = body.trim();
    for (final image in images) {
      request.files.add(await _multipartImage(image));
    }

    final response = await _sendMultipart(
      request,
      'Poruku nije moguće poslati',
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return AdminSupportTicketMessage.fromJson(decoded);
  }

  /// Raw bytes of one message photo
  /// (`GET /SupportTickets/{id}/messages/{messageId}/photos/{photoId}`), for
  /// `Image.memory` via the shared `AuthenticatedImage` widget.
  Future<Uint8List> fetchPhotoBytes(
    int ticketId,
    int messageId,
    int photoId,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/SupportTickets/$ticketId/messages/$messageId/photos/$photoId',
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSupportTicketException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  /// `POST /SupportTickets/{id}/close` (Open -> Closed; requires
  /// `SupportTickets.Manage`). The backend 400s if already closed.
  Future<AdminSupportTicket> close(int id) => _postTransition(id, 'close');

  /// `POST /SupportTickets/{id}/reopen` (Closed -> Open; requires
  /// `SupportTickets.Manage`). The backend 400s if already open.
  Future<AdminSupportTicket> reopen(int id) => _postTransition(id, 'reopen');

  Future<AdminSupportTicket> _postTransition(int id, String action) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/SupportTickets/$id/$action');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSupportTicketException(
        _messageFor(response, 'Tiket nije moguće sačuvati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return AdminSupportTicket.fromJson(decoded);
  }

  /// Builds a `MultipartFile` for an image, sniffing its content type from the
  /// magic bytes (falling back to the extension, then to image/jpeg) - same
  /// reasoning as `CustomerSupportTicketService._multipartImage`.
  Future<http.MultipartFile> _multipartImage(File imageFile) async {
    final headerBytes = await imageFile.openRead(0, 12).first;
    final mimeType =
        lookupMimeType(imageFile.path, headerBytes: headerBytes) ??
        'image/jpeg';
    return http.MultipartFile.fromPath(
      'files',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    );
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminSupportTicketException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminSupportTicketException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminSupportTicketException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminSupportTicketException('Greška mreže: ${e.message}');
    }
  }

  /// Sends a multipart request, mapping transport failures and non-2xx
  /// statuses to an `AdminSupportTicketException` with [fallback] as the base
  /// message.
  Future<http.Response> _sendMultipart(
    http.MultipartRequest request,
    String fallback,
  ) async {
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AdminSupportTicketException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminSupportTicketException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminSupportTicketException('Greška mreže: ${e.message}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AdminSupportTicketException(_messageFor(response, fallback));
    }

    return response;
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
