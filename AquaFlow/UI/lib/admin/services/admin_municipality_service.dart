import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_municipality.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminMunicipalityService {
  AdminMunicipalityService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminMunicipalityPage> fetch({
    required int page,
    required int pageSize,
    String? name,
    int? cityId,
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
    if (cityId != null) {
      query['CityId'] = '$cityId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Municipalities',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminMunicipalityException(
        _messageFor(response, 'Općine nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminMunicipalityException('Općine su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminMunicipalityException('Lista općina je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminMunicipality.fromJson)
        .toList();

    return AdminMunicipalityPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Full unfiltered list (bounded to 200) for dropdown/lookup use, e.g. the
  /// Settlement tab's parent filter/dialog and the Users editor's Općina step.
  Future<List<AdminMunicipality>> fetchAll() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Municipalities').replace(
      queryParameters: {'PageSize': '200', 'SortBy': 'Name'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminMunicipalityException(
        _messageFor(response, 'Općine nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List) {
      throw const AdminMunicipalityException('Lista općina je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminMunicipality.fromJson)
        .toList();
  }

  Future<AdminMunicipality> create({
    required String name,
    required String code,
    required int cityId,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Municipalities');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'code': code, 'cityId': cityId}),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminMunicipalityException(
        _messageFor(response, 'Općinu nije moguće dodati'),
      );
    }

    return _decodeMunicipality(response.body);
  }

  Future<AdminMunicipality> update(
    int id, {
    required String name,
    required String code,
    required int cityId,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Municipalities/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'code': code, 'cityId': cityId}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminMunicipalityException(
        _messageFor(response, 'Općinu nije moguće sačuvati'),
      );
    }

    return _decodeMunicipality(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Municipalities/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminMunicipalityException(
        _messageFor(response, 'Općinu nije moguće obrisati'),
      );
    }
  }

  AdminMunicipality _decodeMunicipality(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminMunicipalityException('Općina je u neispravnom formatu.');
    }
    return AdminMunicipality.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminMunicipalityException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminMunicipalityException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminMunicipalityException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminMunicipalityException('Greška mreže: ${e.message}');
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
