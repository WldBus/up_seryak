import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/fake_network.dart';
import 'core/router.dart';
import 'repositories/in_memory_show_repository.dart';
import 'repositories/in_memory_theatre_repository.dart';
import 'repositories/show_repository.dart';
import 'repositories/theatre_repository.dart';
import 'state/show_list_notifier.dart';
import 'state/theatre_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FakeNetwork()),
        Provider<TheatreRepository>(
          create: (context) =>
              InMemoryTheatreRepository(context.read<FakeNetwork>()),
        ),
        Provider<ShowRepository>(
          create: (context) =>
              InMemoryShowRepository(context.read<FakeNetwork>()),
        ),
        // Загрузку запускает сам экран, когда прочитает условия из адреса
        ChangeNotifierProvider(
          create: (context) => ShowListNotifier(
            context.read<ShowRepository>(),
            context.read<TheatreRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TheatreListNotifier(context.read<TheatreRepository>()),
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
      routerConfig: router,
    );
  }
}
