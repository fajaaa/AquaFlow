import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/city_lookup.dart';
import '../models/municipality_lookup.dart';
import '../models/settlement_lookup.dart';
import 'location_lookup_exception.dart';
import 'token_storage.dart';

/// Read-only City -> Municipality -> Settlement lookups for the cascading
/// Grad -> Općina -> Naselje address pickers used outside the admin desktop
/// (e.g. the mobile `AccountEditScreen` and the collector's request cards).
/// `/Cities`, `/Municipalities`, `/Settlements` reads need no special
/// permission (only their writes are gated behind `Locations.Manage`), so any
/// authenticated role can call these. Mirrors the admin `AdminCityService` /
/// `AdminMunicipalityService` / `AdminSettlementService` `fetchAll()` shape
/// (bounded to 200, sorted by name) without the CRUD methods, which mobile
/// roles never need.
class LocationLookupService {
  LocationLookupService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<CityLookup>> fetchCities() =>
      _fetchList('Cities', CityLookup.fromJson);

  Future<List<MunicipalityLookup>> fetchMunicipalities() =>
      _fetchList('Municipalities', MunicipalityLookup.fromJson);

  Future<List<SettlementLookup>> fetchSettlements() =>
      _fetchList('Settlements', SettlementLookup.fromJson);

  Future<List<T>> _fetchList<T>(
    String resource,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/$resource').replace(
      queryParameters: {'PageSize': '200', 'SortBy': 'Name'},
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw LocationLookupException(
        _messageFor(response, 'Šifarnik nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    final itemsJson = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (itemsJson is! List) {
      throw const LocationLookupException('Lista je u neispravnom formatu.');
    }

    return itemsJson.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const LocationLookupException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw LocationLookupException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const LocationLookupException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw LocationLookupException('Greška mreže: ${e.message}');
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
