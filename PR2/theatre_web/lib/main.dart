import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/fake_network.dart';
import 'core/form_guard.dart';
import 'core/router.dart';
import 'core/storage_notice.dart';
import 'repositories/actor_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/local_store.dart';
import 'repositories/persistent_actor_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_show_repository.dart';
import 'repositories/persistent_spectator_repository.dart';
import 'repositories/persistent_theatre_repository.dart';
import 'repositories/show_repository.dart';
import 'repositories/spectator_repository.dart';
import 'repositories/theatre_repository.dart';
import 'state/actor_list_notifier.dart';
import 'state/catalog.dart';
import 'state/genre_list_notifier.dart';
import 'state/show_list_notifier.dart';
import 'state/spectator_list_notifier.dart';
import 'state/theatre_list_notifier.dart';

Future<void> main() async {
  // без этого будет ошибка: ниже до runApp есть await
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // сначала открываю хранилище и читаю данные, а потом уже запускаю
  // приложение — так сообщение про сброс старых данных готово сразу
  final prefs = await SharedPreferences.getInstance();
  final notice = StorageNotice();
  final store = LocalStore(prefs, notice);
  final network = FakeNetwork();

  final ShowRepository shows = PersistentShowRepository(network, store);
  final TheatreRepository theatres = PersistentTheatreRepository(
    network,
    store,
  );
  final GenreRepository genres = PersistentGenreRepository(network, store);
  final ActorRepository actors = PersistentActorRepository(network, store);
  final SpectatorRepository spectators = PersistentSpectatorRepository(
    network,
    store,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: network),
        ChangeNotifierProvider.value(value: notice),
        Provider(create: (_) => FormGuard()),
        Provider.value(value: shows),
        Provider.value(value: theatres),
        Provider.value(value: genres),
        Provider.value(value: actors),
        Provider.value(value: spectators),
        ChangeNotifierProvider(
          create: (_) => Catalog(theatres, genres, actors),
        ),
        // load() тут не вызываю: список грузит сам экран, когда прочитает
        // фильтры из адреса
        ChangeNotifierProvider(
          create: (context) => ShowListNotifier(shows, context.read<Catalog>()),
        ),
        ChangeNotifierProvider(
          create: (_) => TheatreListNotifier(theatres, shows, actors),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ActorListNotifier(actors, shows, context.read<Catalog>()),
        ),
        ChangeNotifierProvider(create: (_) => GenreListNotifier(genres, shows)),
        ChangeNotifierProvider(
          create: (_) => SpectatorListNotifier(spectators),
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
