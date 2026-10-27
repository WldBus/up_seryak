import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theatre_web/core/api_test_mode.dart';
import 'package:theatre_web/core/connection_status.dart';
import 'package:theatre_web/core/form_guard.dart';
import 'package:theatre_web/models/app_user.dart';
import 'package:theatre_web/models/genre.dart';
import 'package:theatre_web/models/list_query.dart';
import 'package:theatre_web/models/page_result.dart';
import 'package:theatre_web/repositories/actor_repository.dart';
import 'package:theatre_web/repositories/auth_api.dart';
import 'package:theatre_web/repositories/genre_repository.dart';
import 'package:theatre_web/repositories/theatre_repository.dart';
import 'package:theatre_web/screens/genres/genre_form_screen.dart';
import 'package:theatre_web/screens/genres/genre_list_screen.dart';
import 'package:theatre_web/state/auth_notifier.dart';
import 'package:theatre_web/state/catalog.dart';
import 'package:theatre_web/state/genre_list_notifier.dart';

// Тесты виджетов (ПР6): настоящий экран жанров, но вместо сервера —
// подставной репозиторий, а вход — через подставной AuthApi.

const _genres = [Genre(id: 1, name: 'Драма'), Genre(id: 2, name: 'Комедия')];

PageResult<Genre> _page(List<Genre> items) =>
    PageResult(items: items, page: 1, size: 10, total: items.length);

/// Репозиторий жанров без сервера. Что вернёт find, задаётся в тесте.
class FakeGenreRepository implements GenreRepository {
  Future<PageResult<Genre>> Function() onFind;
  int findCalls = 0;

  FakeGenreRepository(List<Genre> items) : onFind = (() async => _page(items));

  @override
  Future<PageResult<Genre>> find(ListQuery query) {
    findCalls++;
    return onFind();
  }

  @override
  Future<List<Genre>> findAll() async => _genres;

  // остальное этим тестам не нужно
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _NoTheatres implements TheatreRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _NoActors implements ActorRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

/// Вход с нужной ролью без сервера.
class _RoleAuthApi implements AuthApi {
  final Role role;

  _RoleAuthApi(this.role);

  @override
  Future<AuthResult> login(String username, String password) async =>
      AuthResult(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 60,
        user: AppUser(
          id: 1,
          username: username,
          fullName: 'Тестовый пользователь',
          email: 'test@theatre.local',
          role: role,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Future<AuthNotifier> _signedIn(Role role) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthNotifier(
    await SharedPreferences.getInstance(),
    _RoleAuthApi(role),
    sessionLimit: const Duration(minutes: 30),
    inactivityTimeout: const Duration(minutes: 3),
  );
  await auth.login(role.code, 'Passw0rd!');
  return auth;
}

/// Приложение из одного раздела «Жанры» со всеми нужными провайдерами.
Widget buildTestApp({
  required GenreRepository repository,
  required AuthNotifier auth,
  String location = '/genres',
  ConnectionStatus? connection,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/genres',
        builder: (_, state) => GenreListScreen(
          query: ListQuery.fromParams(
            state.uri.queryParameters,
            sortFields: Genre.sortFields,
          ),
        ),
      ),
      GoRoute(path: '/genres/new', builder: (_, _) => const GenreFormScreen()),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      if (connection != null) ChangeNotifierProvider.value(value: connection),
      ChangeNotifierProvider(create: (_) => ApiTestMode()),
      Provider(create: (_) => FormGuard()),
      ChangeNotifierProvider(
        create: (_) => GenreListNotifier(
          repository,
          Catalog(_NoTheatres(), repository, _NoActors()),
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // вход — в setUp, вне «поддельного» времени testWidgets: таймер сессии
  // тогда настоящий и не мешает проверке незавершённых таймеров
  late AuthNotifier admin;
  late AuthNotifier viewer;

  setUp(() async {
    admin = await _signedIn(Role.admin);
    viewer = await _signedIn(Role.viewer);
  });

  tearDown(() async {
    await admin.logout(callServer: false);
    await viewer.logout(callServer: false);
  });

  testWidgets('пока список грузится, виден индикатор загрузки', (tester) async {
    final repo = FakeGenreRepository(_genres)
      ..onFind = () => Completer<PageResult<Genre>>().future; // не ответит
    await tester.pumpWidget(buildTestApp(repository: repo, auth: admin));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Драма'), findsNothing);
  });

  testWidgets('список показывает сообщение при пустом результате', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(repository: FakeGenreRepository([]), auth: admin),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка загрузки — текст и кнопка «Повторить», она работает', (
    tester,
  ) async {
    final repo = FakeGenreRepository(_genres)
      ..onFind = () async => throw Exception('сервер недоступен');
    await tester.pumpWidget(buildTestApp(repository: repo, auth: admin));
    await tester.pumpAndSettle();

    expect(find.textContaining('сервер недоступен'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    repo.onFind = () async => _page(_genres); // сервер «починили»
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Драма'), findsOneWidget);
    expect(repo.findCalls, 2);
  });

  testWidgets('связь вернулась — список загружается сам, без кнопки', (
    tester,
  ) async {
    final connection = ConnectionStatus(ping: () async => true);
    final repo = FakeGenreRepository(_genres)
      ..onFind = () async => throw Exception('нет связи');
    // так делает Dio при сбое сети
    connection.reportFailure();
    await tester.pumpWidget(
      buildTestApp(repository: repo, auth: admin, connection: connection),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);

    repo.onFind = () async => _page(_genres);
    connection.reportSuccess(); // первый удачный запрос после сбоя
    await tester.pumpAndSettle();

    expect(find.text('Комедия'), findsOneWidget);
    expect(repo.findCalls, 2);
  });

  testWidgets('форма не отправляется с пустым названием', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        repository: FakeGenreRepository(_genres),
        auth: admin,
        location: '/genres/new',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Создать'));
    await tester.pump();

    // create не вызывался: иначе подставной репозиторий бросил бы ошибку
    expect(find.text('Укажите название'), findsOneWidget);
  });

  testWidgets('зрителю не видны «Добавить» и выбор строк, админу видны', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(repository: FakeGenreRepository(_genres), auth: viewer),
    );
    await tester.pumpAndSettle();

    expect(find.text('Драма'), findsOneWidget); // список зритель видит
    expect(find.text('Добавить'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    await tester.pumpWidget(
      buildTestApp(repository: FakeGenreRepository(_genres), auth: admin),
    );
    await tester.pumpAndSettle();

    expect(find.text('Добавить'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets);
  });
}
