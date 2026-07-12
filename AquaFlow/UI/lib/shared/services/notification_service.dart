import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/notification_page.dart';
import '../models/user_notification_item.dart';
import 'notification_exception.dart';
import 'token_storage.dart';

class NotificationService {
  NotificationService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<NotificationPage> fetchMine({
    required int page,
    required int pageSize,
    String? type,
  }) async {
    final token = await _requireToken();
    final selectedType = type?.trim();

    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };
    if (selectedType != null && selectedType.isNotEmpty) {
      query['Type'] = selectedType;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/UserNotifications/mine',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(response, 'Obavijesti nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const NotificationException('Obavijesti su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const NotificationException('Lista obavijesti je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(UserNotificationItem.fromJson)
        .toList();

    return NotificationPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Looks up the caller's inbox row for [notificationId] via
  /// `/UserNotifications/mine?NotificationId=` - used to resolve a push's
  /// `notificationId` data payload (see `NotificationService.InsertAsync` on
  /// the backend) to a full [UserNotificationItem] when nothing is already
  /// loaded in memory, e.g. a cold start from a tapped notification. Returns
  /// null when no matching row exists for the signed-in user.
  Future<UserNotificationItem?> fetchByNotificationId(
    int notificationId,
  ) async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/UserNotifications/mine')
        .replace(
          queryParameters: {
            'NotificationId': '$notificationId',
            'PageSize': '1',
          },
        );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(response, 'Obavijest nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const NotificationException('Obavijest je u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List || itemsJson.isEmpty) return null;

    final first = itemsJson.first;
    if (first is! Map<String, dynamic>) return null;
    return UserNotificationItem.fromJson(first);
  }

  /// Number of unread inbox rows for the signed-in user, used for the mobile
  /// shells' "Obavijesti" tab badge. Backed by the same `/UserNotifications/
  /// mine` endpoint as [fetchMine] - `IsRead=false` + `IncludeTotalCount=true`
  /// + `PageSize=1` so only the count is paid for, not a full page of items.
  Future<int> fetchUnreadCount() async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/UserNotifications/mine')
        .replace(
          queryParameters: {
            'IsRead': 'false',
            'IncludeTotalCount': 'true',
            'PageSize': '1',
          },
        );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(
          response,
          'Broj nepročitanih obavijesti nije moguće učitati',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const NotificationException('Odgovor je u neispravnom formatu.');
    }

    return (decoded['totalCount'] as num?)?.toInt() ?? 0;
  }

  /// Persists a read receipt for [userNotificationId] via `PATCH
  /// /UserNotifications/{id}` (`{"readAt": "ISO8601 UTC"}`). The owner of
  /// the row may only patch `ReadAt` this way - any other field throws a
  /// `ClientException` on the backend (`UserNotificationsController.Patch`).
  Future<void> markAsRead(int userNotificationId) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/UserNotifications/$userNotificationId',
    );

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'readAt': DateTime.now().toUtc().toIso8601String()}),
      ),
    );

    if (response.statusCode != 200) {
      throw NotificationException(
        _messageFor(response, 'Obavijest nije moguće označiti kao pročitanu'),
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const NotificationException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw NotificationException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const NotificationException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw NotificationException('Greška mreže: ${e.message}');
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
