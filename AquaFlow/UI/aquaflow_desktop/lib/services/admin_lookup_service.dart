import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/lookup_item.dart';
import 'package:aquaflow_desktop/services/admin_lookup_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/authenticated_client.dart';

class AdminLookupService {
  AdminLookupService({http.Client? client, Duration? timeout})
    : _client = client ?? AuthenticatedClient.instance,
      _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  /// In-memory cache of active items per route, shared for the app session.
  static final Map<String, List<LookupItem>> _activeCache = {};

  static void clearCache([String? route]) {
    if (route == null) {
      _activeCache.clear();
    } else {
      _activeCache.remove(route);
    }
  }

  Future<LookupItemPage> fetchPage(
    String route, {
    String? name,
    bool? isActive,
    required int page,
    required int pageSize,
  }) async {
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
    };
    final nameText = name?.trim();
    if (nameText != null && nameText.isNotEmpty) query['Name'] = nameText;
    if (isActive != null) query['IsActive'] = '$isActive';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/$route',
    ).replace(queryParameters: query);
    final response = await _send(() => _client.get(uri));
    if (response.statusCode != 200) {
      throw AdminLookupException(
        _messageFor(response, 'Šifarnik nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const AdminLookupException('Šifarnik je u neispravnom formatu.');
    }
    final items = (decoded['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(LookupItem.fromJson)
        .toList();
    return LookupItemPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// All active items for [route], sorted by sort order; cached per route.
  Future<List<LookupItem>> fetchActive(String route) async {
    final cached = _activeCache[route];
    if (cached != null) return cached;

    final all = <LookupItem>[];
    var page = 1;
    while (true) {
      final result = await fetchPage(
        route,
        isActive: true,
        page: page,
        pageSize: 100,
      );
      all.addAll(result.items);
      if (result.items.isEmpty || all.length >= result.totalCount) break;
      page++;
    }
    all.sort((a, b) {
      final bySort = a.sortOrder.compareTo(b.sortOrder);
      return bySort != 0 ? bySort : a.name.compareTo(b.name);
    });
    final result = List<LookupItem>.unmodifiable(all);
    _activeCache[route] = result;
    return result;
  }

  Future<LookupItem> create(String route, LookupItemDraft draft) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$route');
    try {
      final response = await _send(
        () => _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        ),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw AdminLookupException(
          _messageFor(response, 'Stavku nije moguće dodati'),
        );
      }
      return _decode(response.body);
    } finally {
      clearCache(route);
    }
  }

  Future<LookupItem> update(String route, int id, LookupItemDraft draft) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$route/$id');
    try {
      final response = await _send(
        () => _client.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        ),
      );
      if (response.statusCode != 200) {
        throw AdminLookupException(
          _messageFor(response, 'Stavku nije moguće sačuvati'),
        );
      }
      return _decode(response.body);
    } finally {
      clearCache(route);
    }
  }

  Future<void> delete(String route, int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$route/$id');
    try {
      final response = await _send(() => _client.delete(uri));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw AdminLookupException(
          _messageFor(response, 'Stavku nije moguće obrisati'),
        );
      }
    } finally {
      clearCache(route);
    }
  }

  LookupItem _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminLookupException('Stavka je u neispravnom formatu.');
    }
    return LookupItem.fromJson(decoded);
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminLookupException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminLookupException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminLookupException('Greška mreže: ${e.message}');
    }
  }

  String _messageFor(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['title'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Not JSON; use the status-based message.
    }
    return '$fallback (HTTP ${response.statusCode}).';
  }
}
