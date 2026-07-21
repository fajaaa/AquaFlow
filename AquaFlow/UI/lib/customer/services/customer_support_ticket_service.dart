import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;

import 'package:aquaflow_desktop/customer/models/customer_support_ticket.dart';
import 'package:aquaflow_desktop/customer/models/customer_support_ticket_message.dart';
import 'package:aquaflow_desktop/customer/models/customer_support_ticket_page.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Support tickets of the signed-in customer: list own (`GET /SupportTickets/mine`),
/// read one thread (`GET /SupportTickets/{id}`), open a new ticket
/// (`POST /SupportTickets`), reply on it (`POST /SupportTickets/{id}/messages`),
/// and fetch a message photo's bytes. No `CustomerId`/`Status`/`IsFromStaff` is
/// ever sent - the backend forces all of them from the JWT (see
/// `SupportTicketsController`), so this service can never act under someone
/// else's name or forge a "staff" reply. Follows the `CustomerFaultReportService`
/// template; create/addMessage are multipart because the ticket photos ride
/// along in the same request.
class CustomerSupportTicketService {
  CustomerSupportTicketService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// One page of the caller's tickets, newest activity first. The backend pins
  /// `CustomerId` to the caller from the JWT, so this only ever returns the
  /// signed-in customer's own tickets (every status). Sorted by
  /// `LastMessageAt` descending (the backend default, sent explicitly here).
  Future<CustomerSupportTicketPage> fetchMine({
    required int page,
    int pageSize = 20,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/SupportTickets/mine').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'LastMessageAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerSupportTicketException(
        _messageFor(response, 'Tikete nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerSupportTicketException(
        'Lista je u neispravnom formatu.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerSupportTicket.fromJson)
        .toList();

    return CustomerSupportTicketPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// The full thread of one ticket (`GET /SupportTickets/{id}`, backend pins
  /// ownership to the caller): header fields plus every message and its photo
  /// metadata. Used by the detail/chat screen.
  Future<CustomerSupportTicket> fetchById(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/SupportTickets/$id');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerSupportTicketException(
        _messageFor(response, 'Tiket nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerSupportTicket.fromJson(decoded);
  }

  /// Opens a new ticket with its first message and optional photos
  /// (`POST /SupportTickets`, multipart form fields `subject`/`body` +
  /// `IFormFileCollection files`). The backend resolves the caller's
  /// `CustomerProfile` from the JWT and forces `CustomerId`/`Status`, so none of
  /// those are sent here. Returns the freshly created ticket detail (its first
  /// message carries the uploaded photos).
  Future<CustomerSupportTicket> createTicket({
    required String subject,
    required String body,
    List<File> images = const [],
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/SupportTickets');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['subject'] = subject.trim()
      ..fields['body'] = body.trim();
    for (final image in images) {
      request.files.add(await _multipartImage(image));
    }

    final response = await _sendMultipart(
      request,
      'Tiket nije moguće kreirati',
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerSupportTicket.fromJson(decoded);
  }

  /// Appends a reply (with optional photos) to [ticketId]
  /// (`POST /SupportTickets/{id}/messages`, multipart form field `body` +
  /// `IFormFileCollection files`). `IsFromStaff` is derived server-side from the
  /// caller's permission, so a customer's reply is always stored as
  /// non-staff. The backend rejects a reply to a Closed ticket (-> 400).
  Future<CustomerSupportTicketMessage> addMessage(
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
      throw const CustomerSupportTicketException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerSupportTicketMessage.fromJson(decoded);
  }

  /// Raw bytes of one message photo
  /// (`GET /SupportTickets/{id}/messages/{messageId}/photos/{photoId}`), for
  /// `Image.memory` via the shared `AuthenticatedImage` widget - no endpoint in
  /// this app serves images without a Bearer token, so there is no plain URL to
  /// hand to `Image.network`.
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
      throw CustomerSupportTicketException(
        _messageFor(response, 'Fotografiju nije moguće učitati'),
      );
    }

    return response.bodyBytes;
  }

  /// Builds a `MultipartFile` for an image, sniffing its content type from the
  /// magic bytes (falling back to the extension, then to image/jpeg). Same
  /// reasoning as `CustomerFaultReportService.uploadPhoto`:
  /// `MultipartFile.fromPath` without an explicit contentType falls back to
  /// application/octet-stream for a cache file with no/unrecognized extension
  /// (e.g. from the Android Photo Picker), which the backend's content-type
  /// whitelist then rejects.
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
      throw const CustomerSupportTicketException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerSupportTicketException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerSupportTicketException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerSupportTicketException('Greška mreže: ${e.message}');
    }
  }

  /// Sends a multipart request, mapping transport failures and non-2xx statuses
  /// to a `CustomerSupportTicketException` with [fallback] as the base message.
  Future<http.Response> _sendMultipart(
    http.MultipartRequest request,
    String fallback,
  ) async {
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw CustomerSupportTicketException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerSupportTicketException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerSupportTicketException('Greška mreže: ${e.message}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CustomerSupportTicketException(_messageFor(response, fallback));
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
