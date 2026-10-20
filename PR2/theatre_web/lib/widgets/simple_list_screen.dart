import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router.dart';
import '../models/entity.dart';
import '../models/list_query.dart';
import '../state/entity_list_notifier.dart';
import 'debounced_field.dart';
import 'entity_list_view.dart';
import 'entity_table.dart';
import 'network_toggle.dart';

/// Экран списка для сущностей с ListQuery: поиск, удалённые, сортировка
/// и страницы. Театры, актёры, жанры и зрители отличаются только
/// заголовком, колонками и подписями.
class SimpleListScreen<
  T extends Entity,
  N extends EntityListNotifier<T, ListQuery>
>
    extends StatefulWidget {
  /// фильтры из адреса
  final ListQuery query;
  final String title;

  /// адрес раздела, например '/theatres'
  final String path;
  final String searchLabel;
  final List<TableColumnSpec<T>> columns;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;

  const SimpleListScreen({
    super.key,
    required this.query,
    required this.title,
    required this.path,
    required this.searchLabel,
    required this.columns,
    required this.titleOf,
    required this.subtitleOf,
  });

  @override
  State<SimpleListScreen<T, N>> createState() => _SimpleListScreenState<T, N>();
}

class _SimpleListScreenState<
  T extends Entity,
  N extends EntityListNotifier<T, ListQuery>
>
    extends State<SimpleListScreen<T, N>> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SimpleListScreen<T, N> old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _sync();
  }

  /// отдаю фильтры в notifier после кадра —
  /// во время build вызывать notifyListeners() нельзя
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<N>().sync(widget.query);
    });
  }

  /// любое изменение фильтров — переход на новый адрес
  void _go(ListQuery q) => context.go(listLocation(widget.path, q.toParams()));

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final path = widget.path;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('$path/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
          const NetworkToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: EntityListView<T, N>(
        filters: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: DebouncedField(
                value: q.search,
                label: widget.searchLabel,
                icon: Icons.search,
                onChanged: (v) => _go(q.copyWith(search: v)),
              ),
            ),
            FilterChip(
              label: const Text('Показать удалённые'),
              selected: q.includeDeleted,
              onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
            ),
            if (q.hasFilters)
              TextButton.icon(
                onPressed: () => _go(q.reset()),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Сбросить'),
              ),
          ],
        ),
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        hasFilters: q.hasFilters,
        onResetFilters: () => _go(q.reset()),
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        onPage: (page) => _go(q.copyWith(page: page)),
        onSize: (size) => _go(q.copyWith(size: size)),
        onOpen: (e) => context.go('$path/${e.id}'),
        onEdit: (e) => context.go('$path/${e.id}/edit'),
        titleOf: widget.titleOf,
        subtitleOf: widget.subtitleOf,
        columns: widget.columns,
      ),
    );
  }
}
