import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/customer_profile.dart';
import 'profile_exception.dart';
import 'token_storage.dart';

/// Loads the signed-in user's profile from the backend. Right now only the
/// customer profile (`GET /CustomerProfiles`) is needed - it is the only
/// profile that carries a first/last name.
///
/// The bearer token is read from [TokenStorage] and attached to every request.
/// Network/HTTP failures throw [ProfileException] with a user-safe message; a
/// successful call that matches no profile returns null (e.g. an admin or
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
    final token = await _tokenStorage.readAccessToken();
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

  void dispose() => _client.close();
}
