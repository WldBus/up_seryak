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
import '../screens/actors/actor_list_screen.dart';
import '../screens/genres/genre_details_screen.dart';
import '../screens/genres/genre_list_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/shows/show_details_screen.dart';
import '../screens/shows/show_list_screen.dart';
import '../screens/spectators/spectator_details_screen.dart';
import '../screens/spectators/spectator_list_screen.dart';
import '../screens/theatres/theatre_details_screen.dart';
import '../screens/theatres/theatre_list_screen.dart';
import '../models/app_user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/home_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/deferred_screen.dart';
import 'form_guard.dart';
import 'permissions.dart';

// Редкие разделы — отложенная загрузка (ПР6): формы нужны только
// администратору, касса — кассиру, пользователи и статистика — админу.
// Их код собирается в отдельные файлы и скачивается при первом открытии.
import '../screens/actors/actor_form_screen.dart' deferred as actor_form;
import '../screens/admin/stats_screen.dart' deferred as stats;
import '../screens/admin/users_screen.dart' deferred as users;
import '../screens/bookings/cash_desk_screen.dart' deferred as cash_desk;
import '../screens/genres/genre_form_screen.dart' deferred as genre_form;
import '../screens/shows/show_form_screen.dart' deferred as show_form;
import '../screens/spectators/spectator_form_screen.dart'
    deferred as spectator_form;
import '../screens/theatres/theatre_form_screen.dart' deferred as theatre_form;

/// Собирает адрес списка вместе с фильтрами, например /shows?search=…&sort=date,desc
String listLocation(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();

String showsLocation(ShowQuery q) => listLocation('/shows', q.toParams());

int? _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '');

/// Если в форме что-то поменяли и не сохранили — спрашиваем, точно ли уйти.
Future<bool> _confirmExit(BuildContext context, GoRouterState state) =>
    context.read<FormGuard>().confirmLeave(context);

/// Куда вернуть после входа. Только свои адреса: иначе в ссылку на вход
/// можно подложить чужой сайт.
String? safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  // на экран «Доступ запрещён» после входа возвращать незачем
  if (from.startsWith('/login') ||
      from.startsWith('/register') ||
      from.startsWith('/forbidden')) {
    return null;
  }
  return from;
}

/// Маршрутизатор с защитой адресов.
///
/// Проверка входа — в общем redirect, проверка роли — в redirect
/// конкретного маршрута. Именно в redirect, а не в build экрана: иначе экран
/// успел бы мелькнуть. Но это только удобство: даже если обойти redirect,
/// сервер на чужую операцию ответит 403.
GoRouter buildRouter(AuthNotifier auth) {
  /// маршрут доступен, только если у роли есть право, иначе — экран отказа
  GoRouterRedirect only(bool Function(Role? role) check) =>
      (context, state) => check(auth.role)
      ? null
      : '/forbidden?from=${Uri.encodeComponent(state.uri.toString())}';

  /// на каждую сущность 4 маршрута: список, новая запись, карточка, правка.
  /// new обязательно выше :id — маршруты проверяются по порядку, и иначе
  /// /shows/new попадёт в /shows/:id. Карточку и форму сделал отдельными
  /// маршрутами, а не вложенными в список, а то под ними строился список
  /// с пустыми фильтрами и сбрасывал их
  List<GoRoute> entity({
    required String path,
    required Widget Function(Map<String, String> params) list,
    required Widget Function(int? id) details,
    required Widget Function(int? id) form,
    required bool Function(Role? role) canRead,
    required bool Function(Role? role) canEdit,
  }) => [
    GoRoute(
      path: path,
      redirect: only(canRead),
      // фильтры берём только из адреса, поэтому в новой вкладке и после
      // кнопки «назад» будет тот же список
      builder: (context, state) => list(state.uri.queryParameters),
    ),
    GoRoute(
      path: '$path/new',
      redirect: only(canEdit),
      onExit: _confirmExit,
      builder: (context, state) => form(null),
    ),
    GoRoute(
      path: '$path/:id',
      redirect: only(canRead),
      builder: (context, state) => details(_id(state)),
    ),
    GoRoute(
      path: '$path/:id/edit',
      redirect: only(canEdit),
      onExit: _confirmExit,
      builder: (context, state) => form(_id(state)),
    ),
  ];

  return GoRouter(
    initialLocation: '/',
    // при каждом notifyListeners() у сессии (вход, выход, обновление
    // токена) redirect пересчитывается. без этого после входа так и
    // остался бы экран входа
    refreshListenable: auth,
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;
      final isPublic = path == '/login' || path == '/register';
      // не вошёл и идёт на закрытый адрес — на вход, запомнив, куда шёл
      if (!loggedIn && !isPublic) {
        final from = state.uri.toString();
        return from == '/'
            ? '/login'
            : '/login?from=${Uri.encodeComponent(from)}';
      }
      // уже вошёл и открыл вход — туда, куда шёл, или на главную
      if (loggedIn && isPublic) {
        return safeFrom(state.uri.queryParameters['from']) ?? '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(from: state.uri.queryParameters['from']),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/forbidden',
            builder: (context, state) =>
                ForbiddenScreen(from: state.uri.queryParameters['from']),
          ),
          ...entity(
            path: '/shows',
            list: (p) => ShowListScreen(query: ShowQuery.fromParams(p)),
            details: (id) => ShowDetailsScreen(id: id),
            form: (id) => DeferredScreen(
              load: show_form.loadLibrary,
              builder: () => show_form.ShowFormScreen(id: id),
            ),
            canRead: canViewCatalog,
            canEdit: canEditCatalog,
          ),
          ...entity(
            path: '/theatres',
            list: (p) => TheatreListScreen(
              query: ListQuery.fromParams(p, sortFields: Theatre.sortFields),
            ),
            details: (id) => TheatreDetailsScreen(id: id),
            form: (id) => DeferredScreen(
              load: theatre_form.loadLibrary,
              builder: () => theatre_form.TheatreFormScreen(id: id),
            ),
            canRead: canViewCatalog,
            canEdit: canEditCatalog,
          ),
          ...entity(
            path: '/actors',
            list: (p) => ActorListScreen(
              query: ListQuery.fromParams(p, sortFields: Actor.sortFields),
            ),
            details: (id) => ActorDetailsScreen(id: id),
            form: (id) => DeferredScreen(
              load: actor_form.loadLibrary,
              builder: () => actor_form.ActorFormScreen(id: id),
            ),
            canRead: canViewCatalog,
            canEdit: canEditCatalog,
          ),
          ...entity(
            path: '/genres',
            list: (p) => GenreListScreen(
              query: ListQuery.fromParams(p, sortFields: Genre.sortFields),
            ),
            details: (id) => GenreDetailsScreen(id: id),
            form: (id) => DeferredScreen(
              load: genre_form.loadLibrary,
              builder: () => genre_form.GenreFormScreen(id: id),
            ),
            canRead: canViewCatalog,
            canEdit: canEditCatalog,
          ),
          ...entity(
            path: '/spectators',
            list: (p) => SpectatorListScreen(
              query: ListQuery.fromParams(p, sortFields: Spectator.sortFields),
            ),
            details: (id) => SpectatorDetailsScreen(id: id),
            form: (id) => DeferredScreen(
              load: spectator_form.loadLibrary,
              builder: () => spectator_form.SpectatorFormScreen(id: id),
            ),
            canRead: canManageSpectators,
            canEdit: canManageSpectators,
          ),
          // у каждой роли свой экран, недоступный остальным
          GoRoute(
            path: '/my-bookings',
            redirect: only(canSeeOwnBookings),
            builder: (context, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: '/cash-desk',
            redirect: only(canUseCashDesk),
            builder: (context, state) => DeferredScreen(
              load: cash_desk.loadLibrary,
              builder: () => cash_desk.CashDeskScreen(),
            ),
          ),
          GoRoute(
            path: '/users',
            redirect: only(canManageUsers),
            builder: (context, state) => DeferredScreen(
              load: users.loadLibrary,
              builder: () => users.UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            redirect: only(canSeeStats),
            builder: (context, state) => DeferredScreen(
              load: stats.loadLibrary,
              builder: () => stats.StatsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
