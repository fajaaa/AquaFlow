import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_tariff.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_tariff_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminTariffService {
  AdminTariffService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminTariffPage> fetch({
    required int page,
    required int pageSize,
    String? name,
    bool? isActive,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    final nameText = name?.trim();
    if (nameText != null && nameText.isNotEmpty) {
      query['Name'] = nameText;
    }
    if (isActive != null) {
      query['IsActive'] = '$isActive';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Tariffs',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminTariffException(
        _messageFor(response, 'Tarife nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminTariffException('Tarife su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminTariffException('Lista tarifa je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminTariff.fromJson)
        .toList();

    return AdminTariffPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AdminTariff> create(AdminTariffDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Tariffs');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminTariffException(
        _messageFor(response, 'Tarifu nije moguće dodati'),
      );
    }

    return _decodeTariff(response.body);
  }

  Future<AdminTariff> update(int id, AdminTariffDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Tariffs/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminTariffException(
        _messageFor(response, 'Tarifu nije moguće sačuvati'),
      );
    }

    return _decodeTariff(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Tariffs/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminTariffException(
        _messageFor(response, 'Tarifu nije moguće obrisati'),
      );
    }
  }

  AdminTariff _decodeTariff(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminTariffException('Tarifa je u neispravnom formatu.');
    }
    return AdminTariff.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminTariffException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminTariffException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AdminTariffException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminTariffException('Greška mreže: ${e.message}');
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
