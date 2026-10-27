import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/api_test_mode.dart';
import 'core/config.dart';
import 'core/connection_status.dart';
import 'core/form_guard.dart';
import 'core/router.dart';
import 'repositories/actor_repository.dart';
import 'repositories/admin_repository.dart';
import 'repositories/api_actor_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_show_repository.dart';
import 'repositories/api_spectator_repository.dart';
import 'repositories/api_theatre_repository.dart';
import 'repositories/auth_api.dart';
import 'repositories/booking_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/show_repository.dart';
import 'repositories/spectator_repository.dart';
import 'repositories/theatre_repository.dart';
import 'state/actor_list_notifier.dart';
import 'state/admin_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/bookings_notifier.dart';
import 'state/catalog.dart';
import 'state/genre_list_notifier.dart';
import 'state/show_list_notifier.dart';
import 'state/spectator_list_notifier.dart';
import 'state/theatre_list_notifier.dart';
import 'widgets/connection_banner.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  // без этого будет ошибка: ниже до runApp есть await
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // токены лежат в localStorage, поэтому сессию восстанавливаю до того,
  // как построится интерфейс: иначе после F5 мелькнул бы экран входа
  final prefs = await SharedPreferences.getInstance();
  // одна на всё приложение: и вход, и данные сообщают, есть ли связь
  final connection = ConnectionStatus.forServer(apiBaseUrl);
  // у запросов входа свой Dio без обновления токена (см. AuthApi)
  final auth = AuthNotifier(
    prefs,
    DioAuthApi(buildDio(connection: connection)),
    sessionLimit: sessionLimit,
    inactivityTimeout: inactivityTimeout,
  );
  await auth.restore();
  final router = buildRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connection),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: SessionScope(router: router),
    ),
  );
}

/// Все провайдеры данных. Они пересоздаются, когда меняется пользователь:
/// после выхода и входа под другим именем на экране не должно остаться
/// чужих данных (например, броней прошлого зрителя).
class SessionScope extends StatelessWidget {
  final GoRouter router;

  const SessionScope({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthNotifier, int?>((a) => a.user?.id);
    final auth = context.read<AuthNotifier>();

    return MultiProvider(
      key: ValueKey(userId),
      providers: [
        ChangeNotifierProvider(create: (_) => ApiTestMode()),
        // токен подставляется в каждый запрос, а при 401 Dio сам
        // обновит его через auth.refreshTokens и повторит запрос
        Provider<Dio>(
          create: (context) => buildDio(
            testMode: context.read<ApiTestMode>(),
            connection: context.read<ConnectionStatus>(),
            tokenProvider: () => auth.accessToken,
            onUnauthorized: auth.refreshTokens,
          ),
        ),
        Provider(create: (_) => FormGuard()),
        // Единственное место, где меняется реализация (ПР4): репозитории
        // строятся из Dio, экраны получают те же интерфейсы
        ProxyProvider<Dio, ShowRepository>(
          update: (_, dio, _) => ApiShowRepository(dio),
        ),
        ProxyProvider<Dio, TheatreRepository>(
          update: (_, dio, _) => ApiTheatreRepository(dio),
        ),
        ProxyProvider<Dio, GenreRepository>(
          update: (_, dio, _) => ApiGenreRepository(dio),
        ),
        ProxyProvider<Dio, ActorRepository>(
          update: (_, dio, _) => ApiActorRepository(dio),
        ),
        ProxyProvider<Dio, SpectatorRepository>(
          update: (_, dio, _) => ApiSpectatorRepository(dio),
        ),
        ProxyProvider<Dio, BookingRepository>(
          update: (_, dio, _) => ApiBookingRepository(dio),
        ),
        ProxyProvider<Dio, AdminRepository>(
          update: (_, dio, _) => ApiAdminRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => Catalog(
            context.read<TheatreRepository>(),
            context.read<GenreRepository>(),
            context.read<ActorRepository>(),
          ),
        ),
        // load() тут не вызываю: список грузит сам экран, когда прочитает
        // фильтры из адреса
        ChangeNotifierProvider(
          create: (context) => ShowListNotifier(
            context.read<ShowRepository>(),
            context.read<Catalog>(),
            context.read<SpectatorRepository>(),
            context.read<BookingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TheatreListNotifier(
            context.read<TheatreRepository>(),
            context.read<Catalog>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ActorListNotifier(
            context.read<ActorRepository>(),
            context.read<Catalog>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GenreListNotifier(
            context.read<GenreRepository>(),
            context.read<Catalog>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SpectatorListNotifier(context.read<SpectatorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BookingsNotifier(context.read<BookingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminNotifier(context.read<AdminRepository>()),
        ),
      ],
      child: TheatreApp(router: router),
    );
  }
}

class TheatreApp extends StatelessWidget {
  final GoRouter router;

  const TheatreApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Театральная касса',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8E1B2E),
        useMaterial3: true,
        // диалоги на широком мониторе не растягиваются во всю ширину
        dialogTheme: const DialogThemeData(
          constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
        ),
      ),
      // чтобы календарь и выбор времени были на русском. Cupertino-переводы
      // убрал (ПР6): виджетов в стиле iOS тут нет, а это переводы на все языки
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
      // следит за неактивностью над всеми экранами, пока человек в системе
      // и полоса «нет связи с сервером» над любым экраном, включая вход
      builder: (context, child) => InactivityWatcher(
        child: Column(
          children: [
            const ConnectionBanner(),
            Expanded(child: child!),
          ],
        ),
      ),
    );
  }
}
