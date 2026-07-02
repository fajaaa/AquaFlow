import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/company_settings.dart';
import 'company_settings_exception.dart';
import 'token_storage.dart';

/// Loads and saves the company-wide settings (`/CompanySettings`). Only an admin
/// reaches this from the account screen, but the backend endpoint is the same
/// authenticated CRUD resource as any other.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Network/HTTP failures throw [CompanySettingsException] with a user-safe
/// message. The base URL always comes from [ApiConfig.baseUrl] - the host is
/// never hardcoded here.
class CompanySettingsService {
  CompanySettingsService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// Fetches the single company-settings row. Throws
  /// [CompanySettingsException] when the list is empty (no settings seeded).
  Future<CompanySettings> fetch() async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/CompanySettings?PageSize=1');

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CompanySettingsException(
        _messageFor(response, 'Could not load company settings'),
      );
    }

    // List endpoints return PageResult<T> = { items: [...], totalCount: int? }.
    final decoded = jsonDecode(response.body);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (items is! List || items.isEmpty) {
      throw const CompanySettingsException('No company settings were found.');
    }

    final first = items.first;
    if (first is! Map<String, dynamic>) {
      throw const CompanySettingsException('Company settings are malformed.');
    }
    return CompanySettings.fromJson(first);
  }

  /// Saves [settings] via `PUT /CompanySettings/{id}` and returns the updated
  /// row echoed back by the backend.
  Future<CompanySettings> update(CompanySettings settings) async {
    final token = await _requireToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/CompanySettings/${settings.id}');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings.toUpdateJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw CompanySettingsException(
        _messageFor(response, 'Could not save company settings'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CompanySettingsException('Company settings are malformed.');
    }
    return CompanySettings.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      throw const CompanySettingsException('You are not signed in.');
    }
    return token;
  }

  /// Runs an HTTP call, mapping transport failures to a user-safe exception.
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CompanySettingsException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CompanySettingsException(
        'The server took too long to respond.',
      );
    } on http.ClientException catch (e) {
      throw CompanySettingsException('Network error: ${e.message}');
    }
  }

  /// Builds an error message, preferring the backend's `{ message, errors }`
  /// body (e.g. validation failures) and falling back to the HTTP status.
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
