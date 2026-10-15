import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/router.dart';
import '../models/genre.dart';
import '../models/show.dart';
import '../models/show_query.dart';
import '../state/show_list_notifier.dart';
import '../widgets/debounced_field.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/network_toggle.dart';

class ShowListScreen extends StatefulWidget {
  /// Условия отбора, прочитанные из адреса.
  final ShowQuery query;

  const ShowListScreen({super.key, required this.query});

  @override
  State<ShowListScreen> createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ShowListScreen old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _sync();
  }

  /// Передаёт условия из адреса в notifier. Отложено до конца кадра:
  /// notifyListeners() во время построения дерева запрещён.
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShowListNotifier>().sync(widget.query);
    });
  }

  /// Любое изменение условий — это переход на новый адрес. Экран
  /// перестраивается из адреса, а в истории браузера остаётся шаг назад.
  void _go(ShowQuery q) => context.go(showsLocation(q));

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final notifier = context.watch<ShowListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Спектакли'),
        actions: const [NetworkToggle(), SizedBox(width: 8)],
      ),
      body: EntityListView<Show, ShowListNotifier>(
        filters: _filters(q, notifier),
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        hasFilters: q.hasFilters,
        onResetFilters: () => _go(ShowQuery(size: q.size)),
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        onPage: (page) => _go(q.copyWith(page: page)),
        onSize: (size) => _go(q.copyWith(size: size)),
        onOpen: (s) => context.go('/shows/${s.id}'),
        titleOf: (s) => s.title,
        subtitleOf: (s) =>
            '${notifier.theatreName(s.theatreId)} · '
            '${formatDateTime(s.date)} · ${formatPrice(s.price)}',
        columns: [
          TableColumnSpec(
            label: 'Название',
            sortField: 'title',
            build: (s) => Text(s.title),
          ),
          TableColumnSpec(label: 'Код', build: (s) => Text(s.code)),
          TableColumnSpec(
            label: 'Театр',
            build: (s) => Text(notifier.theatreName(s.theatreId)),
          ),
          TableColumnSpec(
            label: 'Дата',
            sortField: 'date',
            build: (s) => Text(formatDateTime(s.date)),
          ),
          TableColumnSpec(
            label: 'Длительность',
            sortField: 'duration',
            numeric: true,
            build: (s) => Text(formatDuration(s.duration)),
          ),
          TableColumnSpec(
            label: 'Цена',
            sortField: 'price',
            numeric: true,
            build: (s) => Text(formatPrice(s.price)),
          ),
          TableColumnSpec(
            label: 'Свободно',
            numeric: true,
            build: (s) => Text('${s.seatsAvailable} / ${s.seatsTotal}'),
          ),
        ],
      ),
    );
  }

  Widget _filters(ShowQuery q, ShowListNotifier notifier) {
    // Wrap переносит поля на следующую строку, когда окно узкое
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: DebouncedField(
            value: q.search,
            label: 'Поиск по названию или коду',
            icon: Icons.search,
            onChanged: (v) => _go(q.copyWith(search: v)),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<int?>(
            // Значение из адреса может не совпасть ни с одним пунктом
            // (испорченная ссылка) — тогда показываем «Все»
            initialValue: genres.any((g) => g.id == q.genreId)
                ? q.genreId
                : null,
            // key заставляет поле перечитать значение при смене адреса
            key: ValueKey('genre-${q.genreId}'),
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Жанр',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все')),
              for (final g in genres)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
            ],
            onChanged: (v) => _go(q.copyWith(genreId: v)),
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<int?>(
            initialValue: notifier.theatres.any((t) => t.id == q.theatreId)
                ? q.theatreId
                : null,
            key: ValueKey('theatre-${q.theatreId}-${notifier.theatres.length}'),
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Театр',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все')),
              for (final t in notifier.theatres)
                DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => _go(q.copyWith(theatreId: v)),
          ),
        ),
        SizedBox(
          width: 110,
          child: DebouncedField(
            value: q.priceFrom?.toString() ?? '',
            label: 'Цена от',
            numeric: true,
            onChanged: (v) => _go(q.copyWith(priceFrom: int.tryParse(v))),
          ),
        ),
        SizedBox(
          width: 110,
          child: DebouncedField(
            value: q.priceTo?.toString() ?? '',
            label: 'Цена до',
            numeric: true,
            onChanged: (v) => _go(q.copyWith(priceTo: int.tryParse(v))),
          ),
        ),
        FilterChip(
          label: const Text('Показать удалённые'),
          selected: q.includeDeleted,
          onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
        ),
        if (q.hasFilters)
          TextButton.icon(
            onPressed: () => _go(ShowQuery(size: q.size)),
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Сбросить'),
          ),
      ],
    );
  }
}
