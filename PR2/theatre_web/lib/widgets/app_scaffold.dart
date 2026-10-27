import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/format.dart';
import '../core/permissions.dart';
import '../core/router.dart';
import '../models/app_user.dart';
import '../state/actor_list_notifier.dart';
import '../state/auth_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../state/show_list_notifier.dart';
import '../state/spectator_list_notifier.dart';
import '../state/theatre_list_notifier.dart';

typedef _Section = ({
  String path,
  IconData icon,
  String label,
  bool Function(Role? role) allowed,
});

/// Общий каркас: сверху строка с пользователем и кнопкой выхода, меню
/// снизу на телефоне и сбоку на компьютере. В меню только разделы,
/// доступные роли.
class AppScaffold extends StatelessWidget {
  final String location;
  final Widget child;

  const AppScaffold({super.key, required this.location, required this.child});

  static final List<_Section> _all = [
    (path: '/', icon: Icons.home, label: 'Главная', allowed: canViewCatalog),
    (
      path: '/shows',
      icon: Icons.theater_comedy,
      label: 'Спектакли',
      allowed: canViewCatalog,
    ),
    (
      path: '/theatres',
      icon: Icons.account_balance,
      label: 'Театры',
      allowed: canViewCatalog,
    ),
    (
      path: '/actors',
      icon: Icons.person,
      label: 'Актёры',
      allowed: canViewCatalog,
    ),
    (
      path: '/genres',
      icon: Icons.category,
      label: 'Жанры',
      allowed: canViewCatalog,
    ),
    (
      path: '/spectators',
      icon: Icons.badge,
      label: 'Зрители',
      allowed: canManageSpectators,
    ),
    (
      path: '/my-bookings',
      icon: Icons.confirmation_number_outlined,
      label: 'Мои брони',
      allowed: canSeeOwnBookings,
    ),
    (
      path: '/cash-desk',
      icon: Icons.point_of_sale,
      label: 'Касса',
      allowed: canUseCashDesk,
    ),
    (
      path: '/users',
      icon: Icons.manage_accounts,
      label: 'Пользователи',
      allowed: canManageUsers,
    ),
    (
      path: '/stats',
      icon: Icons.bar_chart,
      label: 'Статистика',
      allowed: canSeeStats,
    ),
  ];

  int? _index(List<_Section> sections) {
    final i = sections.indexWhere(
      (s) => s.path == '/' ? location == '/' : location.startsWith(s.path),
    );
    return i == -1 ? null : i;
  }

  void _select(BuildContext context, String path) {
    // в списки возвращаемся с теми фильтрами, которые были до этого
    final params = switch (path) {
      '/shows' => context.read<ShowListNotifier>().query.toParams(),
      '/theatres' => context.read<TheatreListNotifier>().query.toParams(),
      '/actors' => context.read<ActorListNotifier>().query.toParams(),
      '/genres' => context.read<GenreListNotifier>().query.toParams(),
      '/spectators' => context.read<SpectatorListNotifier>().query.toParams(),
      _ => const <String, String>{},
    };
    context.go(listLocation(path, params));
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final role = context.select<AuthNotifier, Role?>((a) => a.role);
    final sections = [
      for (final s in _all)
        if (s.allowed(role)) s,
    ];
    final index = _index(sections);
    final content = Column(
      children: [
        const _UserBar(),
        Expanded(child: child),
      ],
    );

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index ?? 0,
          onDestinationSelected: (i) => _select(context, sections[i].path),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (final s in sections)
              NavigationDestination(icon: Icon(s.icon), label: s.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => _select(context, sections[i].path),
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final s in sections)
                NavigationRailDestination(
                  icon: Icon(s.icon),
                  label: Text(s.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// Строка сверху: кто вошёл, его роль, до скольких действует сессия, выход.
class _UserBar extends StatelessWidget {
  const _UserBar();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ends = auth.sessionEndsAt;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // имя с ролью — в Expanded, а не Flexible + Spacer: те делят
            // свободное место пополам, и кнопка «Выйти» уезжала на середину
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(user.role.label),
                  ),
                ],
              ),
            ),
            if (ends != null && screenSizeOf(context) != ScreenSize.compact)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'сессия до ${formatTime(ends)}',
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            TextButton.icon(
              onPressed: () => auth.logout(message: 'Вы вышли из системы.'),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
