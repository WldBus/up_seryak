import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router.dart';
import '../models/theatre.dart';
import '../models/theatre_query.dart';
import '../state/theatre_list_notifier.dart';
import '../widgets/debounced_field.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/network_toggle.dart';

class TheatreListScreen extends StatefulWidget {
  final TheatreQuery query;

  const TheatreListScreen({super.key, required this.query});

  @override
  State<TheatreListScreen> createState() => _TheatreListScreenState();
}

class _TheatreListScreenState extends State<TheatreListScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TheatreListScreen old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TheatreListNotifier>().sync(widget.query);
    });
  }

  void _go(TheatreQuery q) => context.go(theatresLocation(q));

  @override
  Widget build(BuildContext context) {
    final q = widget.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Театры'),
        actions: const [NetworkToggle(), SizedBox(width: 8)],
      ),
      body: EntityListView<Theatre, TheatreListNotifier>(
        filters: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: DebouncedField(
                value: q.search,
                label: 'Поиск по названию или городу',
                icon: Icons.search,
                onChanged: (v) => _go(q.copyWith(search: v)),
              ),
            ),
            FilterChip(
              label: const Text('Показать удалённые'),
              selected: q.includeDeleted,
              onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
            ),
          ],
        ),
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        hasFilters: q.hasFilters,
        onResetFilters: () => _go(TheatreQuery(size: q.size)),
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        onPage: (page) => _go(q.copyWith(page: page)),
        onSize: (size) => _go(q.copyWith(size: size)),
        onOpen: (t) => context.go('/theatres/${t.id}'),
        titleOf: (t) => t.name,
        subtitleOf: (t) => '${t.city} · ${t.hallSeats} мест',
        columns: [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (t) => Text(t.name),
          ),
          TableColumnSpec(
            label: 'Город',
            sortField: 'city',
            build: (t) => Text(t.city),
          ),
          TableColumnSpec(label: 'Адрес', build: (t) => Text(t.address)),
          TableColumnSpec(
            label: 'Мест в зале',
            sortField: 'hallSeats',
            numeric: true,
            build: (t) => Text('${t.hallSeats}'),
          ),
          TableColumnSpec(
            label: 'Основан',
            sortField: 'founded',
            numeric: true,
            build: (t) => Text('${t.founded}'),
          ),
        ],
      ),
    );
  }
}
