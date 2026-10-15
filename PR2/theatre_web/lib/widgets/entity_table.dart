import 'package:flutter/material.dart';

/// Описание одной колонки таблицы.
class TableColumnSpec<T> {
  final String label;

  /// Поле сортировки; null — по колонке не сортируют.
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

/// Обобщённая таблица для любой сущности: книги, театры, спектакли
/// различаются только списком колонок.
class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool>? onSelectAll;

  /// Строки, которые нельзя выделить (например, уже удалённые).
  final bool Function(T item)? isDisabled;
  final ValueChanged<T>? onOpen;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.isDisabled,
    this.onOpen,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final sortIndex = columns.indexWhere(
      (c) => c.sortField != null && c.sortField == sortField,
    );
    final muted = Theme.of(context).disabledColor;

    final table = DataTable(
      // DataTable сам рисует стрелку у активной колонки
      sortColumnIndex: sortIndex == -1 ? null : sortIndex,
      sortAscending: sortAscending,
      showCheckboxColumn: onToggleSelect != null,
      onSelectAll: onSelectAll == null ? null : (v) => onSelectAll!(v ?? false),
      columns: [
        for (final c in columns)
          DataColumn(
            label: Text(c.label),
            numeric: c.numeric,
            onSort: c.sortField == null || onSort == null
                ? null
                : (_, _) => onSort!(c.sortField!),
          ),
        if (actions != null) const DataColumn(label: Text('Действия')),
      ],
      rows: [
        for (final item in items)
          _row(
            context,
            item,
            disabled: isDisabled?.call(item) ?? false,
            muted: muted,
          ),
      ],
    );

    // DataTable не прокручивается и не сжимается: нужна двумерная прокрутка,
    // а minWidth растягивает таблицу на всю ширину широкого окна
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    T item, {
    required bool disabled,
    required Color muted,
  }) {
    final id = idOf(item);
    return DataRow(
      selected: selected.contains(id),
      onSelectChanged: onToggleSelect == null || disabled
          ? null
          : (_) => onToggleSelect!(id),
      cells: [
        for (final c in columns)
          DataCell(
            DefaultTextStyle.merge(
              style: disabled
                  ? TextStyle(
                      color: muted,
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
              child: c.build(item),
            ),
            onTap: onOpen == null ? null : () => onOpen!(item),
          ),
        if (actions != null)
          DataCell(
            Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
          ),
      ],
    );
  }
}
