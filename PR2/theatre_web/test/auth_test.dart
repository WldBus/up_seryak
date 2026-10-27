import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theatre_web/core/api_client.dart';
import 'package:theatre_web/core/api_exceptions.dart';
import 'package:theatre_web/models/app_user.dart';
import 'package:theatre_web/repositories/auth_api.dart';
import 'package:theatre_web/state/auth_notifier.dart';

import 'api_repository_test.dart' show FakeAdapter, jsonBody;

// Обновление токена и выход: без сервера, с подставным AuthApi.

const viewerUser = AppUser(
  id: 3,
  username: 'viewer',
  fullName: 'Иванов Сергей',
  email: 'viewer@theatre.local',
  role: Role.viewer,
  spectatorId: 1,
);

AuthResult tokens(String n, {AppUser user = viewerUser}) => AuthResult(
  accessToken: 'access-$n',
  refreshToken: 'refresh-$n',
  expiresIn: 60,
  user: user,
);

class FakeAuthApi implements AuthApi {
  /// что вернёт обновление; null — сервер ответит 401
  AuthResult? nextRefresh;
  int refreshCalls = 0;

  @override
  Future<AuthResult> login(String username, String password) async {
    if (password != 'Passw0rd!') {
      throw const UnauthorizedException('Неверный логин или пароль.');
    }
    return tokens('1');
  }

  @override
  Future<AuthResult> refresh(String refreshToken) async {
    refreshCalls++;
    // даю другим запросам успеть встать в очередь за этим обновлением
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final r = nextRefresh;
    if (r == null) throw const UnauthorizedException('Токен недействителен.');
    return r;
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {}

  @override
  Future<void> logout(String refreshToken) async {}
}

void main() {
  late SharedPreferences prefs;
  late FakeAuthApi api;
  late AuthNotifier auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = FakeAuthApi();
    auth = AuthNotifier(
      prefs,
      api,
      sessionLimit: const Duration(minutes: 30),
      inactivityTimeout: const Duration(minutes: 3),
    );
  });

  tearDown(() => auth.logout(callServer: false));

  test('неверный пароль — ошибка 401, в хранилище ничего нет', () async {
    await expectLater(
      auth.login('viewer', 'wrong'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(auth.isAuthenticated, isFalse);
    expect(prefs.getString('auth_access_token'), isNull);
  });

  test('после входа токены и профиль сохраняются, пароля нет', () async {
    await auth.login('viewer', 'Passw0rd!');
    expect(auth.role, Role.viewer);
    expect(prefs.getString('auth_access_token'), 'access-1');
    expect(prefs.getString('auth_refresh_token'), 'refresh-1');
    final stored = prefs.getKeys().map((k) => '${prefs.get(k)}').join();
    expect(stored.contains('Passw0rd!'), isFalse);
  });

  test('несколько 401 подряд — обновление уходит одно', () async {
    await auth.login('viewer', 'Passw0rd!');
    api.nextRefresh = tokens('2');
    final results = await Future.wait([
      auth.refreshTokens(),
      auth.refreshTokens(),
      auth.refreshTokens(),
    ]);
    expect(results, [true, true, true]);
    expect(api.refreshCalls, 1);
    expect(auth.accessToken, 'access-2');
  });

  test('обновление вернуло профиль с другой ролью — роль меняется', () async {
    await auth.login('viewer', 'Passw0rd!');
    api.nextRefresh = tokens(
      '2',
      user: AppUser.fromJson({...viewerUser.toJson(), 'role': 'cashier'}),
    );
    await auth.refreshTokens();
    expect(auth.role, Role.cashier);
    final cached = jsonDecode(prefs.getString('auth_user')!) as Map;
    expect(cached['role'], 'cashier');
  });

  test('обновление не удалось — чистый выход с сообщением', () async {
    await auth.login('viewer', 'Passw0rd!');
    api.nextRefresh = null;
    expect(await auth.refreshTokens(), isFalse);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.message, contains('Войдите снова'));
    expect(prefs.getString('auth_refresh_token'), isNull);
  });

  test('подменённая роль в localStorage заменяется настоящей', () async {
    await auth.login('viewer', 'Passw0rd!');
    // «взломщик» правит профиль в DevTools и перезагружает страницу
    await prefs.setString(
      'auth_user',
      jsonEncode({...viewerUser.toJson(), 'role': 'admin'}),
    );
    final reloaded = AuthNotifier(
      prefs,
      api,
      sessionLimit: const Duration(minutes: 30),
      inactivityTimeout: const Duration(minutes: 3),
    );
    await reloaded.restore();
    expect(reloaded.role, Role.admin); // интерфейс обманут...
    api.nextRefresh = tokens('2'); // ...но сервер знает настоящую роль
    await reloaded.refreshTokens();
    expect(reloaded.role, Role.viewer);
    await reloaded.logout(callServer: false);
  });

  test('сессия старше предела при запуске не восстанавливается', () async {
    await auth.login('viewer', 'Passw0rd!');
    final later = AuthNotifier(
      prefs,
      api,
      sessionLimit: const Duration(minutes: 30),
      inactivityTimeout: const Duration(minutes: 3),
      now: () => DateTime.now().add(const Duration(minutes: 31)),
    );
    await later.restore();
    expect(later.isAuthenticated, isFalse);
    expect(later.message, contains('Время сессии истекло'));
  });

  group('RefreshInterceptor', () {
    test('401 → обновление → запрос повторяется с новым токеном', () async {
      var token = 'old';
      var refreshes = 0;
      final dio = buildDio(
        baseUrl: 'http://test',
        tokenProvider: () => token,
        onUnauthorized: () async {
          refreshes++;
          token = 'new';
          return true;
        },
        log: false,
      );
      final adapter = FakeAdapter(
        (o) async => o.headers['Authorization'] == 'Bearer new'
            ? jsonBody(200, {'ok': true})
            : jsonBody(401, {'message': 'Токен истёк'}),
      );
      dio.httpClientAdapter = adapter;

      final res = await dio.get<Map<String, dynamic>>('/api/shows');
      expect(res.data, {'ok': true});
      expect(refreshes, 1);
      expect(adapter.requests, hasLength(2));
    });

    test('сервер всегда отвечает 401 — без бесконечного цикла', () async {
      var refreshes = 0;
      final dio = buildDio(
        baseUrl: 'http://test',
        tokenProvider: () => 'any',
        onUnauthorized: () async {
          refreshes++;
          return true;
        },
        log: false,
      );
      final adapter = FakeAdapter(
        (_) async => jsonBody(401, {'message': 'Токен недействителен'}),
      );
      dio.httpClientAdapter = adapter;

      await expectLater(
        dio.get<Object?>('/api/shows'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 1); // обновили один раз и сдались
      expect(adapter.requests, hasLength(2)); // запрос + один повтор
    });

    test('запросы /auth/ токен не обновляют', () async {
      var refreshes = 0;
      final dio = buildDio(
        baseUrl: 'http://test',
        onUnauthorized: () async {
          refreshes++;
          return true;
        },
        log: false,
      );
      dio.httpClientAdapter = FakeAdapter(
        (_) async => jsonBody(401, {'message': 'Неверный пароль'}),
      );
      await expectLater(
        dio.post<Object?>('/api/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 0);
    });
  });
}
