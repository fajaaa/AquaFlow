import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/customer_profile.dart';
import 'profile_exception.dart';
import 'token_storage.dart';

/// Loads and saves the signed-in user's profile. Right now only the customer
/// profile (`/CustomerProfiles`) is needed - it is the only profile that
/// carries a first/last name.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Network/HTTP failures throw [ProfileException] with a user-safe message; a
/// successful fetch that matches no profile returns null (e.g. an admin or
/// collector, who have no customer profile). The base URL always comes from
/// [ApiConfig.baseUrl] - the host is never hardcoded here.
class ProfileService {
  ProfileService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// Fetches the customer profile owned by [userId], or null when the user has
  /// no customer profile.
  Future<CustomerProfile?> fetchCustomerProfile(int userId) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const ProfileException('You are not signed in.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/CustomerProfiles?UserId=$userId&PageSize=1',
    );

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } on SocketException {
      throw ProfileException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const ProfileException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw ProfileException('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw ProfileException(
        'Could not load your profile (HTTP ${response.statusCode}).',
      );
    }

    // List endpoints return PageResult<T> = { items: [...], totalCount: int? }.
    final decoded = jsonDecode(response.body);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (items is! List || items.isEmpty) return null;

    final first = items.first;
    if (first is! Map<String, dynamic>) return null;
    return CustomerProfile.fromJson(first);
  }

  /// Fetches the CustomerProfile with primary key [customerProfileId]
  /// directly (`GET /CustomerProfiles/{id}`), or null when there is none.
  /// Used by the collector's request cards to show the requesting customer's
  /// naselje/adresa: `WaterMeterRequestResponse.CustomerId` is the
  /// CustomerProfile's own id, not a `User` id, so this looks up by primary
  /// key instead of by `UserId` like [fetchCustomerProfile].
  Future<CustomerProfile?> fetchById(int customerProfileId) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const ProfileException('You are not signed in.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/CustomerProfiles/$customerProfileId',
    );

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } on SocketException {
      throw ProfileException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const ProfileException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw ProfileException('Network error: ${e.message}');
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ProfileException(
        'Could not load the customer profile (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return CustomerProfile.fromJson(decoded);
  }

  /// Creates or updates the caller's own CustomerProfile with a new
  /// first/last name and address (Settlement/Street/HouseNumber). Pass
  /// [existingProfileId] (from [fetchCustomerProfile]) to PATCH the existing
  /// row, or null to create a new one - the latter only applies to a user
  /// (e.g. an admin/collector on mobile) who has no customer profile yet,
  /// since a self-registered customer always has one.
  Future<void> saveProfile({
    required int userId,
    required String firstName,
    required String lastName,
    int? settlementId,
    String? street,
    String? houseNumber,
    int? existingProfileId,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const ProfileException('You are not signed in.');
    }

    final isCreate = existingProfileId == null;
    final uri = isCreate
        ? Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles')
        : Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles/$existingProfileId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      if (isCreate) 'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'settlementId': settlementId,
      'street': street,
      'houseNumber': houseNumber,
    });

    final http.Response response;
    try {
      response = await (isCreate
              ? _client.post(uri, headers: headers, body: body)
              : _client.patch(uri, headers: headers, body: body))
          .timeout(_timeout);
    } on SocketException {
      throw ProfileException(
        'Cannot reach the server at ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const ProfileException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw ProfileException('Network error: ${e.message}');
    }

    final expectedStatus = isCreate ? 201 : 200;
    if (response.statusCode != expectedStatus) {
      throw ProfileException(
        _messageFor(response, 'Could not save your profile'),
      );
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
