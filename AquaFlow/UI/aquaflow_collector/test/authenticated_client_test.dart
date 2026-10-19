// AuthenticatedClient/SessionManager/TokenStorage behaviour: bearer injection,
// 401 -> single-flight refresh -> replay, session expiry vs network failure,
// multipart replay, and the shared in-memory "remember me = false" tokens.
// The same file is duplicated in all 3 Flutter projects (no shared package).

import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aquaflow_collector/shared/config/api_config.dart';
import 'package:aquaflow_collector/shared/providers/auth_provider.dart';
import 'package:aquaflow_collector/shared/services/auth_api_service.dart';
import 'package:aquaflow_collector/shared/services/authenticated_client.dart';
import 'package:aquaflow_collector/shared/services/preferences_api_service.dart';
import 'package:aquaflow_collector/shared/services/push_notification_service.dart';
import 'package:aquaflow_collector/shared/services/session_manager.dart';
import 'package:aquaflow_collector/shared/services/token_storage.dart';

var _jwtCounter = 0;

/// An unsigned but decodable JWT (jwt_decoder only reads the payload).
String _jwt({
  Duration validFor = const Duration(minutes: 15),
  List<String> permissions = const [],
}) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
  return [
    part({'alg': 'HS256', 'typ': 'JWT'}),
    part({
      'Id': '1',
      'Email': 'kenan.fajic@aquaflow.ba',
      'UserRole': 'Admin',
      'IsActive': 'True',
      'Permission': permissions,
      'jti': '${_jwtCounter++}',
      'exp': exp,
    }),
    'signature',
  ].join('.');
}

Uri _api(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

http.Response _tokens(String access, String refresh) => http.Response(
  jsonEncode({'accessToken': access, 'refreshToken': refresh}),
  200,
  headers: {'content-type': 'application/json'},
);

/// Routes `/Access/refresh` to [onRefresh] and everything else to [onApi],
/// recording every request so tests can assert on them.
class _Backend {
  _Backend({required this.onApi, this.onRefresh, this.onOther});

  final FutureOr<http.Response> Function(http.Request request) onApi;
  final FutureOr<http.Response> Function(http.Request request)? onRefresh;
  final FutureOr<http.Response> Function(http.Request request)? onOther;

  final List<http.Request> apiRequests = [];
  final List<http.Request> refreshRequests = [];
  final List<http.Request> otherAccessRequests = [];

  late final MockClient client = MockClient((request) async {
    final path = request.url.path;
    if (path == '/Access/refresh') {
      refreshRequests.add(request);
      return onRefresh!(request);
    }
    if (path.startsWith('/Access/')) {
      otherAccessRequests.add(request);
      return onOther!(request);
    }
    apiRequests.add(request);
    return onApi(request);
  });
}

/// Answers 200 only to the given bearer token, 401 to anything else.
FutureOr<http.Response> Function(http.Request) _acceptOnly(String token) {
  return (request) => request.headers['Authorization'] == 'Bearer $token'
      ? http.Response('{"ok":true}', 200)
      : http.Response('', 401);
}

class _Harness {
  _Harness(this.backend) {
    sessions = SessionManager(
      authService: AuthApiService(client: backend.client),
      tokenStorage: TokenStorage(),
    );
    sessions.onSessionExpired = () => expiredCalls++;
    client = AuthenticatedClient(
      inner: backend.client,
      sessionManager: sessions,
    );
  }

  final _Backend backend;
  late final SessionManager sessions;
  late final AuthenticatedClient client;
  int expiredCalls = 0;
}

/// Never touches Firebase.
class _NoPushService extends PushNotificationService {
  @override
  Future<void> requestPermissionAndRegister() async {}

  @override
  Future<void> unregister() async {}
}

class _CloseTrackingClient extends http.BaseClient {
  _CloseTrackingClient(this._inner);

  final http.Client _inner;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() => closed = true;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TokenStorage.resetMemoryForTesting();
  });

  test('401 -> one refresh -> retry succeeds with the new token', () async {
    final oldAccess = _jwt();
    final newAccess = _jwt();
    await TokenStorage().saveTokens(oldAccess, 'refresh-1');

    final backend = _Backend(
      onApi: _acceptOnly(newAccess),
      onRefresh: (_) => _tokens(newAccess, 'refresh-2'),
    );
    final h = _Harness(backend);

    final response = await h.client.get(_api('/Tariffs'));

    expect(response.statusCode, 200);
    expect(backend.refreshRequests, hasLength(1));
    expect(jsonDecode(backend.refreshRequests.single.body), {
      'refreshToken': 'refresh-1',
    });
    expect(backend.apiRequests, hasLength(2));
    expect(
      backend.apiRequests[0].headers['Authorization'],
      'Bearer $oldAccess',
    );
    expect(
      backend.apiRequests[1].headers['Authorization'],
      'Bearer $newAccess',
    );
    expect(await TokenStorage().getAccessToken(), newAccess);
    expect(await TokenStorage().getRefreshToken(), 'refresh-2');
    expect(h.expiredCalls, 0);
  });

  test('3 parallel 401s -> exactly one POST /Access/refresh', () async {
    final newAccess = _jwt();
    await TokenStorage().saveTokens(_jwt(), 'refresh-1');

    final backend = _Backend(
      onApi: _acceptOnly(newAccess),
      onRefresh: (_) async {
        // Keep the refresh in flight while the other 401s arrive.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _tokens(newAccess, 'refresh-2');
      },
    );
    final h = _Harness(backend);

    final responses = await Future.wait([
      h.client.get(_api('/Invoices')),
      h.client.get(_api('/Payments')),
      h.client.get(_api('/Tariffs')),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(backend.refreshRequests, hasLength(1));
    expect(await TokenStorage().getRefreshToken(), 'refresh-2');
  });

  test(
    'refresh 400 -> tokens cleared, session-expired fired exactly once',
    () async {
      await TokenStorage().saveTokens(_jwt(), 'revoked-refresh');

      final backend = _Backend(
        onApi: (_) => http.Response('', 401),
        onRefresh: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{"message":"Invalid refresh token."}', 400);
        },
      );
      final h = _Harness(backend);

      final responses = await Future.wait([
        for (var i = 0; i < 5; i++) h.client.get(_api('/Users')),
      ]);

      // The original 401 is handed back to each service unchanged.
      expect(responses.map((r) => r.statusCode), everyElement(401));
      expect(backend.refreshRequests, hasLength(1));
      expect(h.expiredCalls, 1);
      expect(await TokenStorage().getAccessToken(), isNull);
      expect(await TokenStorage().getRefreshToken(), isNull);

      // A later request with no session left does not "expire" it again.
      await h.client.get(_api('/Users'));
      expect(h.expiredCalls, 1);
    },
  );

  test(
    'refresh network failure -> no sign-out, service sees a network error',
    () async {
      final access = _jwt();
      await TokenStorage().saveTokens(access, 'refresh-1');

      final backend = _Backend(
        onApi: (_) => http.Response('', 401),
        onRefresh: (_) => throw const SocketException('Network is unreachable'),
      );
      final h = _Harness(backend);

      await expectLater(
        h.client.get(_api('/Users')),
        throwsA(isA<http.ClientException>()),
      );
      expect(h.expiredCalls, 0);
      expect(await TokenStorage().getAccessToken(), access);
      expect(await TokenStorage().getRefreshToken(), 'refresh-1');
    },
  );

  test(
    'multipart upload is replayed after a refresh with the same body',
    () async {
      final newAccess = _jwt();
      await TokenStorage().saveTokens(_jwt(), 'refresh-1');

      final backend = _Backend(
        onApi: _acceptOnly(newAccess),
        onRefresh: (_) => _tokens(newAccess, 'refresh-2'),
      );
      final h = _Harness(backend);

      final photoBytes = List<int>.generate(4096, (i) => i % 256);
      final request =
          http.MultipartRequest('POST', _api('/FaultReports/7/photos'))
            ..fields['note'] = 'curenje'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                photoBytes,
                filename: 'kvar.jpg',
              ),
            );

      final response = await http.Response.fromStream(
        await h.client.send(request),
      );

      expect(response.statusCode, 200);
      expect(backend.apiRequests, hasLength(2));
      final first = backend.apiRequests[0];
      final retry = backend.apiRequests[1];
      expect(
        first.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(retry.headers['content-type'], first.headers['content-type']);
      expect(retry.bodyBytes, first.bodyBytes);
      expect(retry.bodyBytes.length, greaterThan(photoBytes.length));
      expect(retry.headers['Authorization'], 'Bearer $newAccess');
    },
  );

  test('/Access/login 401 is not intercepted', () async {
    await TokenStorage().saveTokens(_jwt(), 'refresh-1');

    final backend = _Backend(
      onApi: (_) => fail('no API call expected'),
      onRefresh: (_) => fail('no refresh expected'),
      onOther: (_) => http.Response('', 401),
    );
    final h = _Harness(backend);

    final response = await h.client.post(
      _api('/Access/login'),
      body: jsonEncode({'email': 'x@y.z', 'password': 'wrong'}),
    );

    expect(response.statusCode, 401);
    expect(backend.otherAccessRequests, hasLength(1));
    expect(backend.otherAccessRequests.single.headers['Authorization'], isNull);
    expect(backend.refreshRequests, isEmpty);
    expect(h.expiredCalls, 0);
  });

  test('an access token about to expire is refreshed before sending', () async {
    final newAccess = _jwt();
    await TokenStorage().saveTokens(
      _jwt(validFor: const Duration(seconds: 10)),
      'refresh-1',
    );

    final backend = _Backend(
      onApi: _acceptOnly(newAccess),
      onRefresh: (_) => _tokens(newAccess, 'refresh-2'),
    );
    final h = _Harness(backend);

    final response = await h.client.get(_api('/Tariffs'));

    expect(response.statusCode, 200);
    expect(backend.refreshRequests, hasLength(1));
    expect(backend.apiRequests, hasLength(1));
    expect(
      backend.apiRequests.single.headers['Authorization'],
      'Bearer $newAccess',
    );
  });

  test('the caller-supplied Authorization header is overridden', () async {
    final access = _jwt();
    await TokenStorage().saveTokens(access, 'refresh-1');

    final backend = _Backend(onApi: _acceptOnly(access));
    final h = _Harness(backend);

    final response = await h.client.get(
      _api('/Tariffs'),
      headers: {'authorization': 'Bearer stale'},
    );

    expect(response.statusCode, 200);
    expect(
      backend.apiRequests.single.headers['Authorization'],
      'Bearer $access',
    );
  });

  test('close() on the shared client never closes the inner client', () async {
    final access = _jwt();
    await TokenStorage().saveTokens(access, 'refresh-1');

    final backend = _Backend(onApi: _acceptOnly(access));
    final inner = _CloseTrackingClient(backend.client);
    final client = AuthenticatedClient(
      inner: inner,
      sessionManager: SessionManager(
        authService: AuthApiService(client: backend.client),
      ),
    );

    // What a screen's dispose() does via `service.dispose()`.
    client.close();

    expect(inner.closed, isFalse);
    expect((await client.get(_api('/Tariffs'))).statusCode, 200);
  });

  group('TokenStorage with remember = false', () {
    test('a second instance sees the in-memory tokens', () async {
      final access = _jwt();
      await TokenStorage().saveTokens(access, 'refresh-1', remember: false);

      final other = TokenStorage();
      expect(await other.getAccessToken(), access);
      expect(await other.getRefreshToken(), 'refresh-1');

      // Nothing was written to the secure store.
      const store = FlutterSecureStorage();
      expect(await store.read(key: 'aquaflow.accessToken'), isNull);
      expect(await store.read(key: 'aquaflow.refreshToken'), isNull);
    });

    test('another service (its own TokenStorage) sends the token', () async {
      final access = _jwt();
      await TokenStorage().saveTokens(access, 'refresh-1', remember: false);

      final backend = _Backend(onApi: _acceptOnly(access));
      final h = _Harness(backend);

      final response = await h.client.get(_api('/Account/me'));

      expect(response.statusCode, 200);
      expect(
        backend.apiRequests.single.headers['Authorization'],
        'Bearer $access',
      );
    });

    test('a refreshed pair stays memory-only', () async {
      final newAccess = _jwt();
      await TokenStorage().saveTokens(_jwt(), 'refresh-1', remember: false);

      final backend = _Backend(
        onApi: _acceptOnly(newAccess),
        onRefresh: (_) => _tokens(newAccess, 'refresh-2'),
      );
      final h = _Harness(backend);

      expect((await h.client.get(_api('/Tariffs'))).statusCode, 200);
      expect(await TokenStorage().getAccessToken(), newAccess);
      const store = FlutterSecureStorage();
      expect(await store.read(key: 'aquaflow.refreshToken'), isNull);
    });
  });

  group('AuthProvider follows SessionManager', () {
    late _Backend backend;
    late _Harness h;
    late AuthProvider auth;
    var uiExpiredCalls = 0;
    late String loginAccess;
    late String refreshedAccess;
    var refreshStatus = 200;

    setUp(() {
      uiExpiredCalls = 0;
      refreshStatus = 200;
      loginAccess = _jwt(permissions: ['Tariffs.Manage']);
      refreshedAccess = _jwt(
        permissions: ['Tariffs.Manage', 'SupportTickets.Manage'],
      );
      backend = _Backend(
        onApi: _acceptOnly(refreshedAccess),
        onRefresh: (_) => refreshStatus == 200
            ? _tokens(refreshedAccess, 'refresh-2')
            : http.Response('', refreshStatus),
        onOther: (request) => switch (request.url.path) {
          '/Access/login' => _tokens(loginAccess, 'refresh-1'),
          '/Access/logout' => http.Response('', 204),
          _ => http.Response('', 404),
        },
      );
      h = _Harness(backend);
      auth = AuthProvider(
        authService: AuthApiService(client: backend.client),
        sessionManager: h.sessions,
        pushNotificationService: _NoPushService(),
        preferencesService: PreferencesApiService(client: backend.client),
        onSessionExpired: () => uiExpiredCalls++,
      );
    });

    tearDown(() => auth.dispose());

    test('a refreshed JWT updates the session (new permissions)', () async {
      expect(await auth.login(email: 'a@b.c', password: 'x'), isTrue);
      expect(auth.session!.hasPermission('SupportTickets.Manage'), isFalse);

      var notified = 0;
      auth.addListener(() => notified++);
      expect((await h.client.get(_api('/Tariffs'))).statusCode, 200);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.session!.hasPermission('SupportTickets.Manage'), isTrue);
      expect(notified, greaterThan(0));
    });

    test(
      'a rejected refresh token signs out once and calls the UI hook',
      () async {
        expect(await auth.login(email: 'a@b.c', password: 'x'), isTrue);
        refreshStatus = 400;

        await Future.wait([
          for (var i = 0; i < 5; i++) h.client.get(_api('/Tariffs')),
        ]);

        expect(auth.status, AuthStatus.unauthenticated);
        expect(auth.session, isNull);
        expect(uiExpiredCalls, 1);
      },
    );

    test('logout revokes the refresh token, then clears storage', () async {
      expect(await auth.login(email: 'a@b.c', password: 'x'), isTrue);

      await auth.logout();

      final logout = backend.otherAccessRequests
          .where((r) => r.url.path == '/Access/logout')
          .single;
      expect(jsonDecode(logout.body), {'refreshToken': 'refresh-1'});
      expect(await TokenStorage().getRefreshToken(), isNull);
      expect(auth.status, AuthStatus.unauthenticated);
      expect(uiExpiredCalls, 0);
    });

    test('logout still completes when /Access/logout fails', () async {
      expect(await auth.login(email: 'a@b.c', password: 'x'), isTrue);
      final failing = AuthProvider(
        authService: AuthApiService(
          client: MockClient((_) => throw const SocketException('offline')),
        ),
        sessionManager: h.sessions,
        pushNotificationService: _NoPushService(),
        preferencesService: PreferencesApiService(client: backend.client),
      );
      addTearDown(failing.dispose);

      await failing.logout();

      expect(await TokenStorage().getAccessToken(), isNull);
      expect(failing.status, AuthStatus.unauthenticated);
    });
  });
}
