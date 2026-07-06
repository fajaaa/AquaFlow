import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_result.dart';
import 'auth_exception.dart';

/// Talks to the backend `AccessController` (`/Access/login`, `/Access/refresh`).
///
/// Every network/HTTP failure is translated into an [AuthException] with a
/// message that is safe to show to the user, so callers only deal with one
/// error type. The base URL always comes from [ApiConfig.baseUrl] - the host is
/// never hardcoded here.
class AuthApiService {
  AuthApiService({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  /// `POST /Access/login` with `{ "email": ..., "password": ... }`.
  Future<AuthResult> login(String email, String password) {
    return _postForTokens(
      '/Access/login',
      {'email': email, 'password': password},
    );
  }

  /// `POST /Access/refresh` with `{ "refreshToken": ... }`. Backend rotates the
  /// pair, so the response carries a fresh access AND refresh token.
  Future<AuthResult> refresh(String refreshToken) {
    return _postForTokens('/Access/refresh', {'refreshToken': refreshToken});
  }

  /// `POST /Access/register` with `{ email, password, phone, firstName,
  /// lastName }`. Always creates a Customer (backend ignores any role input)
  /// plus its `CustomerProfile`. The backend returns the created user, not
  /// tokens, so callers must follow up with [login] to establish a session.
  Future<void> register({
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _post('/Access/register', {
      'email': email,
      'password': password,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
    });

    if (response.statusCode == 201) return;

    throw AuthException(
      _messageForRegisterError(response),
      statusCode: response.statusCode,
    );
  }

  Future<AuthResult> _postForTokens(
    String path,
    Map<String, String> body,
  ) async {
    final response = await _post(path, body);

    if (response.statusCode == 200) {
      return AuthResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw AuthException(
      _messageForError(response),
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      return await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(_timeout);
    } on SocketException {
      throw AuthException(
        'Cannot reach the server at ${ApiConfig.baseUrl}. '
        'Is the backend running and the host reachable from this device?',
      );
    } on TimeoutException {
      throw const AuthException('The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw AuthException('Network error: ${e.message}');
    }
  }

  /// Turns a non-200 response into a friendly message. The backend
  /// ExceptionFilter returns `{ message, errors }` for client errors (400);
  /// 401/429 may have no JSON body.
  String _messageForError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return 'Invalid email or password.';
      case 429:
        return 'Too many attempts. Please wait a minute and try again.';
    }

    final parsed = _tryReadMessage(response.body);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    if (response.statusCode == 400) return 'Invalid email or password.';
    return 'Login failed (HTTP ${response.statusCode}).';
  }

  /// Turns a non-201 `/Access/register` response into a friendly message
  /// (e.g. duplicate email or a validation failure surfaced via `{ message }`).
  String _messageForRegisterError(http.Response response) {
    if (response.statusCode == 429) {
      return 'Too many attempts. Please wait a minute and try again.';
    }

    final parsed = _tryReadMessage(response.body);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    return 'Registration failed (HTTP ${response.statusCode}).';
  }

  String? _tryReadMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
      }
    } catch (_) {
      // Non-JSON body - fall through to a generic message.
    }
    return null;
  }

  void dispose() => _client.close();
}
