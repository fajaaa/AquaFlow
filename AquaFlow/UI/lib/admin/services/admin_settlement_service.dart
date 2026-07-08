import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_settlement.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminSettlementService {
  AdminSettlementService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminSettlementPage> fetch({
    required int page,
    required int pageSize,
    String? name,
    int? municipalityId,
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
    if (municipalityId != null) {
      query['MunicipalityId'] = '$municipalityId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Settlements',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSettlementException(
        _messageFor(response, 'Naselja nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSettlementException('Naselja su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminSettlementException('Lista naselja je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminSettlement.fromJson)
        .toList();

    return AdminSettlementPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Full unfiltered list (bounded to 200) for dropdown/lookup use, e.g. the
  /// Users editor's cascading Naselje step (filtered client-side by
  /// [AdminSettlement.municipalityId]).
  Future<List<AdminSettlement>> fetchAll() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Settlements').replace(
      queryParameters: {'PageSize': '200', 'SortBy': 'Name'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminSettlementException(
        _messageFor(response, 'Naselja nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List) {
      throw const AdminSettlementException('Lista naselja je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminSettlement.fromJson)
        .toList();
  }

  Future<AdminSettlement> create({
    required String name,
    required int municipalityId,
    required String postalCode,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Settlements');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'municipalityId': municipalityId,
          'postalCode': postalCode,
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminSettlementException(
        _messageFor(response, 'Naselje nije moguće dodati'),
      );
    }

    return _decodeSettlement(response.body);
  }

  Future<AdminSettlement> update(
    int id, {
    required String name,
    required int municipalityId,
    required String postalCode,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Settlements/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'municipalityId': municipalityId,
          'postalCode': postalCode,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminSettlementException(
        _messageFor(response, 'Naselje nije moguće sačuvati'),
      );
    }

    return _decodeSettlement(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Settlements/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminSettlementException(
        _messageFor(response, 'Naselje nije moguće obrisati'),
      );
    }
  }

  AdminSettlement _decodeSettlement(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminSettlementException('Naselje je u neispravnom formatu.');
    }
    return AdminSettlement.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminSettlementException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminSettlementException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminSettlementException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminSettlementException('Greška mreže: ${e.message}');
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
