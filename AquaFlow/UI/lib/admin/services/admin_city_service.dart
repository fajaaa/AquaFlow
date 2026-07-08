import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_city.dart';
import 'package:aquaflow_desktop/admin/models/admin_city_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminCityService {
  AdminCityService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminCityPage> fetch({
    required int page,
    required int pageSize,
    String? name,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'Name',
    };

    final nameText = name?.trim();
    if (nameText != null && nameText.isNotEmpty) {
      query['Name'] = nameText;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Cities',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCityException(
        _messageFor(response, 'Gradove nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCityException('Gradovi su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminCityException('Lista gradova je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCity.fromJson)
        .toList();

    return AdminCityPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Full unfiltered list (bounded to 200) for dropdown/lookup use, e.g. the
  /// Municipality tab's parent filter/dialog and the Users editor's Grad step.
  Future<List<AdminCity>> fetchAll() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Cities').replace(
      queryParameters: {'PageSize': '200', 'SortBy': 'Name'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminCityException(
        _messageFor(response, 'Gradove nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List) {
      throw const AdminCityException('Lista gradova je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCity.fromJson)
        .toList();
  }

  Future<AdminCity> create({required String name, required String code}) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Cities');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'code': code}),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminCityException(
        _messageFor(response, 'Grad nije moguće dodati'),
      );
    }

    return _decodeCity(response.body);
  }

  Future<AdminCity> update(
    int id, {
    required String name,
    required String code,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Cities/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'code': code}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminCityException(
        _messageFor(response, 'Grad nije moguće sačuvati'),
      );
    }

    return _decodeCity(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Cities/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminCityException(
        _messageFor(response, 'Grad nije moguće obrisati'),
      );
    }
  }

  AdminCity _decodeCity(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminCityException('Grad je u neispravnom formatu.');
    }
    return AdminCity.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminCityException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminCityException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AdminCityException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminCityException('Greška mreže: ${e.message}');
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
