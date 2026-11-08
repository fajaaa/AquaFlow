import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

/// The app's one HTTP client for authenticated API calls.
///
/// Every service that needs a bearer token uses the shared [instance] instead
/// of its own `http.Client()`, and no longer reads or attaches the token
/// itself. For each request this client:
///
/// 1. buffers the request into a replayable form (an `http.BaseRequest` body
///    stream can only be read once - this covers `http.MultipartRequest`
///    photo uploads too, whose `multipart/form-data; boundary=...`
///    content-type header is copied after finalizing);
/// 2. sets `Authorization: Bearer <access token>` (overriding whatever the
///    caller set), refreshing proactively first when the token expires within
///    [refreshThreshold];
/// 3. on a 401, refreshes once through [SessionManager] (single-flight, so
///    parallel 401s share one `POST /Access/refresh`) and replays the request
///    once with the new token.
///
/// `/Access/*` routes (login/refresh/register/logout) are passed through
/// untouched - their 401 means bad credentials, not an expired session.
///
/// When the refresh token itself is rejected, [SessionManager] clears the
/// tokens and fires its session-expired callback, and the original 401 is
/// handed back to the service. When the refresh fails on the network, the
/// user stays signed in and the service gets an `http.ClientException`,
/// which every service already maps to its own network-error message.
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({
    http.Client? inner,
    SessionManager? sessionManager,
    this.refreshThreshold = const Duration(seconds: 30),
  }) : _inner = inner ?? http.Client(),
       _sessions = sessionManager ?? SessionManager.instance;

  /// The app-wide instance every authenticated service defaults to.
  static final AuthenticatedClient instance = AuthenticatedClient();

  final http.Client _inner;
  final SessionManager _sessions;

  /// How close to expiry an access token may get before it is refreshed
  /// proactively, instead of waiting for the backend's 401.
  final Duration refreshThreshold;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_isAccessRoute(request.url)) return _inner.send(request);

    final replayable = await _ReplayableRequest.capture(request);

    final token = await _sessions.validAccessToken(
      minValidity: refreshThreshold,
    );
    final response = await _inner.send(replayable.build(token));
    if (response.statusCode != 401) return response;

    // The first response must be consumed before it can be either discarded
    // (retry) or handed back unchanged (no retry possible).
    final firstBody = await response.stream.toBytes();

    final retryToken = await _tokenForRetry(token, request.url);
    if (retryToken == null) return _rebuild(response, firstBody);

    return _inner.send(replayable.build(retryToken));
  }

  /// The token to replay a 401'd request with, or null when there is none
  /// (session over, or the refresh failed with an HTTP error).
  Future<String?> _tokenForRetry(String? usedToken, Uri url) async {
    // Another request may already have refreshed while this one was in flight
    // - replay with that token instead of rotating the pair again.
    final current = await _sessions.currentAccessToken();
    if (current != null && current != usedToken) return current;

    final result = await _sessions.refresh();
    switch (result.status) {
      case SessionRefreshStatus.refreshed:
        return result.accessToken;
      case SessionRefreshStatus.invalid:
        return null;
      case SessionRefreshStatus.unavailable:
        if (result.isNetworkError) {
          throw http.ClientException(
            result.errorMessage ?? 'Session refresh failed.',
            url,
          );
        }
        return null;
    }
  }

  static bool _isAccessRoute(Uri url) {
    final path = url.path.toLowerCase();
    return path == '/access' || path.startsWith('/access/');
  }

  static http.StreamedResponse _rebuild(
    http.StreamedResponse response,
    Uint8List body,
  ) {
    return http.StreamedResponse(
      http.ByteStream.fromBytes(body),
      response.statusCode,
      contentLength: body.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  /// Deliberately a no-op: this client is shared by the whole app, and many
  /// services call `_client.close()` from a screen's `dispose()`. Closing the
  /// inner client there would kill HTTP for every other screen.
  @override
  void close() {}
}

/// A fully buffered copy of a request that can be sent any number of times.
class _ReplayableRequest {
  _ReplayableRequest._(this._source, this._headers, this._body);

  final http.BaseRequest _source;
  final Map<String, String> _headers;
  final Uint8List _body;

  static Future<_ReplayableRequest> capture(http.BaseRequest request) async {
    // finalize() first: for a MultipartRequest it is what sets the
    // content-type header carrying the boundary the body bytes were built
    // with.
    final body = await request.finalize().toBytes();
    return _ReplayableRequest._(request, Map.of(request.headers), body);
  }

  http.Request build(String? accessToken) {
    final request = http.Request(_source.method, _source.url)
      ..followRedirects = _source.followRedirects
      ..maxRedirects = _source.maxRedirects
      ..persistentConnection = _source.persistentConnection
      ..headers.addAll(_headers)
      // bodyBytes (unlike `body`) never touches the copied content-type.
      ..bodyBytes = _body;

    // http.Request headers are case-insensitive, so this replaces any
    // `authorization` header the caller set as well.
    if (accessToken == null) {
      request.headers.remove('Authorization');
    } else {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    return request;
  }
}
