import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tariff_lookup.dart';
import 'tariff_lookup_exception.dart';
import 'token_storage.dart';

/// Read-only active-tariff lookup for the collector's reading-entry tariff
/// picker. Lives in `shared` (not `admin`) because `lib/collector` cannot
/// depend on `lib/admin` (see the one-way dependency rule in AGENTS.md) -
/// mirrors [LocationLookupService]'s request/auth/error-mapping template.
/// `/Tariffs` reads need no special permission (only writes are gated behind
/// `Tariffs.Manage`), so any authenticated role can call this.
class TariffLookupService {
  TariffLookupService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<TariffLookup>> fetchActiveTariffs() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Tariffs').replace(
      queryParameters: {
        'IsActive': 'true',
        'PageSize': '200',
        'SortBy': 'Name',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw TariffLookupException(
        _messageFor(response, 'Tarife nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List) {
      throw const TariffLookupException('Lista je u neispravnom formatu.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(TariffLookup.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const TariffLookupException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw TariffLookupException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const TariffLookupException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw TariffLookupException('Greška mreže: ${e.message}');
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
