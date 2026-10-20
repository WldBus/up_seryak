import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/actor.dart';
import '../models/genre.dart';
import '../models/list_query.dart';
import '../models/show_query.dart';
import '../models/spectator.dart';
import '../models/theatre.dart';
import '../screens/actors/actor_details_screen.dart';
import '../screens/actors/actor_form_screen.dart';
import '../screens/actors/actor_list_screen.dart';
import '../screens/genres/genre_details_screen.dart';
import '../screens/genres/genre_form_screen.dart';
import '../screens/genres/genre_list_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/shows/show_details_screen.dart';
import '../screens/shows/show_form_screen.dart';
import '../screens/shows/show_list_screen.dart';
import '../screens/spectators/spectator_details_screen.dart';
import '../screens/spectators/spectator_form_screen.dart';
import '../screens/spectators/spectator_list_screen.dart';
import '../screens/theatres/theatre_details_screen.dart';
import '../screens/theatres/theatre_form_screen.dart';
import '../screens/theatres/theatre_list_screen.dart';
import '../widgets/app_scaffold.dart';
import 'form_guard.dart';

/// Собирает адрес списка вместе с фильтрами, например /shows?search=…&sort=date,desc
String listLocation(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();

String showsLocation(ShowQuery q) => listLocation('/shows', q.toParams());

int? _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '');

/// Если в форме что-то поменяли и не сохранили — спрашиваем, точно ли уйти.
Future<bool> _confirmExit(BuildContext context, GoRouterState state) =>
    context.read<FormGuard>().confirmLeave(context);

/// На каждую сущность 4 маршрута: список, новая запись, карточка, редактирование.
///
/// new обязательно выше :id — маршруты проверяются по порядку, и иначе
/// /shows/new попадёт в /shows/:id.
/// Карточку и форму сделал отдельными маршрутами, а не вложенными в список,
/// а то под ними строился список с пустыми фильтрами и сбрасывал их.
List<GoRoute> _entityRoutes({
  required String path,
  required Widget Function(Map<String, String> params) list,
  required Widget Function(int? id) details,
  required Widget Function(int? id) form,
}) => [
  GoRoute(
    path: path,
    // фильтры берём только из адреса, поэтому в новой вкладке и после
    // кнопки «назад» будет тот же список
    builder: (context, state) => list(state.uri.queryParameters),
  ),
  GoRoute(
    path: '$path/new',
    onExit: _confirmExit,
    builder: (context, state) => form(null),
  ),
  GoRoute(path: '$path/:id', builder: (context, state) => details(_id(state))),
  GoRoute(
    path: '$path/:id/edit',
    onExit: _confirmExit,
    builder: (context, state) => form(_id(state)),
  ),
];

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
        ..._entityRoutes(
          path: '/shows',
          list: (p) => ShowListScreen(query: ShowQuery.fromParams(p)),
          details: (id) => ShowDetailsScreen(id: id),
          form: (id) => ShowFormScreen(id: id),
        ),
        ..._entityRoutes(
          path: '/theatres',
          list: (p) => TheatreListScreen(
            query: ListQuery.fromParams(p, sortFields: Theatre.sortFields),
          ),
          details: (id) => TheatreDetailsScreen(id: id),
          form: (id) => TheatreFormScreen(id: id),
        ),
        ..._entityRoutes(
          path: '/actors',
          list: (p) => ActorListScreen(
            query: ListQuery.fromParams(p, sortFields: Actor.sortFields),
          ),
          details: (id) => ActorDetailsScreen(id: id),
          form: (id) => ActorFormScreen(id: id),
        ),
        ..._entityRoutes(
          path: '/genres',
          list: (p) => GenreListScreen(
            query: ListQuery.fromParams(p, sortFields: Genre.sortFields),
          ),
          details: (id) => GenreDetailsScreen(id: id),
          form: (id) => GenreFormScreen(id: id),
        ),
        ..._entityRoutes(
          path: '/spectators',
          list: (p) => SpectatorListScreen(
            query: ListQuery.fromParams(p, sortFields: Spectator.sortFields),
          ),
          details: (id) => SpectatorDetailsScreen(id: id),
          form: (id) => SpectatorFormScreen(id: id),
        ),
      ],
    ),
  ],
);
