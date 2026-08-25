import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_customer/models/customer_water_meter.dart';
import 'package:aquaflow_customer/models/customer_water_meter_page.dart';
import 'package:aquaflow_customer/services/customer_water_meter_exception.dart';
import 'package:aquaflow_customer/shared/config/api_config.dart';
import 'package:aquaflow_customer/shared/services/token_storage.dart';

/// Loads the signed-in customer's own water meters - [fetchPage] for the
/// paginated "Vodomjeri" tab list, [fetchMine] for callers that need every
/// meter at once (e.g. the fault report dialog's meter dropdown). No
/// CustomerId is sent - the backend pins the filter to the caller's
/// CustomerProfile from the JWT, so this can never return another
/// customer's meters.
class CustomerWaterMeterService {
  CustomerWaterMeterService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// One page of the caller's water meters, newest-installed first. The
  /// backend pins the filter to the caller's CustomerProfile from the JWT,
  /// same as [fetchMine] - this can never return another customer's meters.
  Future<CustomerWaterMeterPage> fetchPage({
    required int page,
    int pageSize = 10,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeters').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'InstalledAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerWaterMeterException(
        _messageFor(response, 'Vodomjere nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerWaterMeterException(
        'Vodomjeri su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerWaterMeterException('Lista vodomjera je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerWaterMeter.fromJson)
        .toList();

    return CustomerWaterMeterPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<List<CustomerWaterMeter>> fetchMine() async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/WaterMeters',
    ).replace(queryParameters: {'PageSize': '100'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerWaterMeterException(
        _messageFor(response, 'Vodomjere nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerWaterMeterException(
        'Vodomjeri su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerWaterMeterException('Lista vodomjera je neispravna.');
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerWaterMeter.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CustomerWaterMeterException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerWaterMeterException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerWaterMeterException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerWaterMeterException('Greška mreže: ${e.message}');
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
