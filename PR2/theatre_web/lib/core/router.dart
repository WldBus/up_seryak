import 'package:go_router/go_router.dart';

import '../models/show_query.dart';
import '../models/theatre_query.dart';
import '../screens/not_found_screen.dart';
import '../screens/show_details_screen.dart';
import '../screens/show_list_screen.dart';
import '../screens/theatre_details_screen.dart';
import '../screens/theatre_list_screen.dart';
import '../widgets/app_scaffold.dart';

/// Адрес списка вместе с условиями отбора: /shows?search=…&sort=date,desc
String showsLocation(ShowQuery q) =>
    Uri(path: '/shows', queryParameters: _orNull(q.toParams())).toString();

String theatresLocation(TheatreQuery q) =>
    Uri(path: '/theatres', queryParameters: _orNull(q.toParams())).toString();

Map<String, String>? _orNull(Map<String, String> p) => p.isEmpty ? null : p;

final router = GoRouter(
  initialLocation: '/shows',
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
  redirect: (context, state) => state.uri.path == '/' ? '/shows' : null,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppScaffold(location: state.uri.path, child: child),
      routes: [
        // Условия отбора берутся только из адреса: открытие ссылки в новой
        // вкладке и кнопка «назад» восстанавливают тот же список
        GoRoute(
          path: '/shows',
          builder: (context, state) => ShowListScreen(
            query: ShowQuery.fromParams(state.uri.queryParameters),
          ),
        ),
        // Карточки — отдельные маршруты, а не вложенные: иначе под карточкой
        // строился бы список с пустыми условиями и сбрасывал фильтры
        GoRoute(
          path: '/shows/:id',
          builder: (context, state) =>
              ShowDetailsScreen(id: int.tryParse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/theatres',
          builder: (context, state) => TheatreListScreen(
            query: TheatreQuery.fromParams(state.uri.queryParameters),
          ),
        ),
        GoRoute(
          path: '/theatres/:id',
          builder: (context, state) => TheatreDetailsScreen(
            id: int.tryParse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);
