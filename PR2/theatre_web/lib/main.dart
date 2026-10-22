import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/api_test_mode.dart';
import 'core/form_guard.dart';
import 'core/router.dart';
import 'repositories/actor_repository.dart';
import 'repositories/api_actor_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_show_repository.dart';
import 'repositories/api_spectator_repository.dart';
import 'repositories/api_theatre_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/show_repository.dart';
import 'repositories/spectator_repository.dart';
import 'repositories/theatre_repository.dart';
import 'state/actor_list_notifier.dart';
import 'state/catalog.dart';
import 'state/genre_list_notifier.dart';
import 'state/show_list_notifier.dart';
import 'state/spectator_list_notifier.dart';
import 'state/theatre_list_notifier.dart';

void main() {
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiTestMode()),
        Provider<Dio>(
          create: (context) => buildDio(testMode: context.read<ApiTestMode>()),
        ),
        Provider(create: (_) => FormGuard()),
        // Единственное место, где поменялась реализация: было
        // Persistent…Repository (localStorage), стало Api…Repository.
        // Экраны и формы получают те же интерфейсы и про сервер не знают
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
      ],
      child: const TheatreApp(),
    ),
  );
}

class TheatreApp extends StatelessWidget {
  const TheatreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Театральная касса',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8E1B2E),
        useMaterial3: true,
      ),
      // чтобы календарь и выбор времени были на русском
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
