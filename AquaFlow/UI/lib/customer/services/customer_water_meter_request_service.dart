import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/customer/models/customer_service_location.dart';
import 'package:aquaflow_desktop/customer/models/customer_water_meter_request.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Water meter requests of the signed-in customer: list own, create a new one,
/// and cancel a still-pending one. No CustomerId is ever sent - the backend
/// resolves and pins it from the JWT, so this service can never touch another
/// customer's requests. Follows the CustomerWaterMeterService template.
class CustomerWaterMeterRequestService {
  CustomerWaterMeterRequestService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<List<CustomerWaterMeterRequest>> fetchMine() async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/WaterMeterRequests',
    ).replace(queryParameters: {'PageSize': '100'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerWaterMeterRequestException(
        _messageFor(response, 'Zahtjeve nije moguće učitati'),
      );
    }

    return _itemsOf(
      response,
    ).map(CustomerWaterMeterRequest.fromJson).toList();
  }

  /// The customer's own service locations, offered as the pick-list when
  /// creating a request. The backend pins `GET /ServiceLocations` to the
  /// caller's CustomerProfile for the Customer role.
  Future<List<CustomerServiceLocation>> fetchMyLocations() async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ServiceLocations',
    ).replace(queryParameters: {'PageSize': '100'});

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerWaterMeterRequestException(
        _messageFor(response, 'Lokacije nije moguće učitati'),
      );
    }

    return _itemsOf(response).map(CustomerServiceLocation.fromJson).toList();
  }

  Future<CustomerWaterMeterRequest> create({
    required int serviceLocationId,
    String? note,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeterRequests');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'serviceLocationId': serviceLocationId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CustomerWaterMeterRequestException(
        _messageFor(response, 'Zahtjev nije moguće poslati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerWaterMeterRequestException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    return CustomerWaterMeterRequest.fromJson(decoded);
  }

  Future<void> cancel(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/WaterMeterRequests/$id/cancel');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerWaterMeterRequestException(
        _messageFor(response, 'Zahtjev nije moguće otkazati'),
      );
    }
  }

  List<Map<String, dynamic>> _itemsOf(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerWaterMeterRequestException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerWaterMeterRequestException(
        'Lista je u neispravnom formatu.',
      );
    }

    return itemsJson.whereType<Map<String, dynamic>>().toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CustomerWaterMeterRequestException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerWaterMeterRequestException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerWaterMeterRequestException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerWaterMeterRequestException('Greška mreže: ${e.message}');
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
