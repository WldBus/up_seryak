import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/router.dart';
import '../state/show_list_notifier.dart';
import '../state/theatre_list_notifier.dart';

/// Каркас с навигацией: снизу на узком окне, сбоку на широком.
class AppScaffold extends StatelessWidget {
  final String location;
  final Widget child;

  const AppScaffold({super.key, required this.location, required this.child});

  static const _destinations = [
    (icon: Icons.theater_comedy, label: 'Спектакли'),
    (icon: Icons.account_balance, label: 'Театры'),
  ];

  int get _index => location.startsWith('/theatres') ? 1 : 0;

  void _select(BuildContext context, int i) {
    // Возвращаемся к списку с теми условиями, что были выбраны раньше
    context.go(
      i == 0
          ? showsLocation(context.read<ShowListNotifier>().query)
          : theatresLocation(context.read<TheatreListNotifier>().query),
    );
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
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
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
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
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
