import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/router.dart';
import '../state/actor_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../state/show_list_notifier.dart';
import '../state/spectator_list_notifier.dart';
import '../state/theatre_list_notifier.dart';

/// Общий каркас с меню: снизу на телефоне, сбоку на компьютере.
class AppScaffold extends StatelessWidget {
  final String location;
  final Widget child;

  const AppScaffold({super.key, required this.location, required this.child});

  static const _sections = [
    (path: '/shows', icon: Icons.theater_comedy, label: 'Спектакли'),
    (path: '/theatres', icon: Icons.account_balance, label: 'Театры'),
    (path: '/actors', icon: Icons.person, label: 'Актёры'),
    (path: '/genres', icon: Icons.category, label: 'Жанры'),
    (path: '/spectators', icon: Icons.badge, label: 'Зрители'),
  ];

  int get _index {
    final i = _sections.indexWhere((s) => location.startsWith(s.path));
    return i == -1 ? 0 : i;
  }

  void _select(BuildContext context, int i) {
    // возвращаемся в список с теми фильтрами, которые были до этого
    final path = _sections[i].path;
    final params = switch (path) {
      '/theatres' => context.read<TheatreListNotifier>().query.toParams(),
      '/actors' => context.read<ActorListNotifier>().query.toParams(),
      '/genres' => context.read<GenreListNotifier>().query.toParams(),
      '/spectators' => context.read<SpectatorListNotifier>().query.toParams(),
      _ => context.read<ShowListNotifier>().query.toParams(),
    };
    context.go(listLocation(path, params));
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _select(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (final s in _sections)
              NavigationDestination(icon: Icon(s.icon), label: s.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => _select(context, i),
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final s in _sections)
                NavigationRailDestination(
                  icon: Icon(s.icon),
                  label: Text(s.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
