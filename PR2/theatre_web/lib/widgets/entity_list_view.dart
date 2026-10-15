import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/entity.dart';
import '../models/page_result.dart';
import '../state/entity_list_notifier.dart';
import '../state/list_state.dart';
import 'entity_table.dart';
import 'pager_bar.dart';

/// Общий экран списка: панель фильтров, полоса выделения, таблица или
/// карточки в зависимости от ширины, пагинация и все состояния загрузки.
/// Конкретный экран задаёт только фильтры, колонки и подписи.
class EntityListView<T extends Entity, N extends EntityListNotifier<T, Object?>>
    extends StatelessWidget {
  final Widget filters;
  final List<TableColumnSpec<T>> columns;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;
  final String? sortField;
  final bool sortAscending;
  final bool hasFilters;
  final VoidCallback onResetFilters;
  final ValueChanged<String> onSort;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;
  final ValueChanged<T> onOpen;

  const EntityListView({
    super.key,
    required this.filters,
    required this.columns,
    required this.titleOf,
    required this.subtitleOf,
    required this.sortField,
    required this.sortAscending,
    required this.hasFilters,
    required this.onResetFilters,
    required this.onSort,
    required this.onPage,
    required this.onSize,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // На узком окне фильтры сворачиваются, иначе под список не остаётся
        // места. Раскрытие панели — локальное состояние ExpansionTile
        if (MediaQuery.sizeOf(context).width < tableBreakpoint)
          ExpansionTile(
            leading: const Icon(Icons.tune),
            title: Text(hasFilters ? 'Фильтры (заданы)' : 'Поиск и фильтры'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [filters],
          )
        else
          Padding(padding: const EdgeInsets.all(12), child: filters),
        if (notifier.hasSelection) _SelectionBar<T, N>(),
        const Divider(height: 1),
        Expanded(
          child: switch (notifier.state) {
            ListLoading() => const Center(child: CircularProgressIndicator()),
            ListFailed(message: final m) => _ErrorView(
              message: m,
              onRetry: () => context.read<N>().load(),
            ),
            ListLoaded(page: final p) when p.items.isEmpty => _EmptyView(
              page: p,
              hasFilters: hasFilters,
              onReset: onResetFilters,
              onFirstPage: () => onPage(1),
            ),
            ListLoaded(page: final p) => _buildItems(context, notifier, p),
          },
        ),
        if (notifier.state case ListLoaded(page: final p) when p.total > 0) ...[
          const Divider(height: 1),
          PagerBar(page: p, onPage: onPage, onSize: onSize),
        ],
      ],
    );
  }

  Widget _buildItems(BuildContext context, N notifier, PageResult<T> page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < tableBreakpoint) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: page.items.length,
            itemBuilder: (context, i) =>
                _card(context, notifier, page.items[i]),
          );
        }
        return EntityTable<T>(
          columns: columns,
          items: page.items,
          idOf: (e) => e.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          onSelectAll: notifier.selectPage,
          isDisabled: (e) => e.isDeleted,
          onOpen: onOpen,
          sortField: sortField,
          sortAscending: sortAscending,
          onSort: onSort,
          actions: (e) => _actions(context, e),
        );
      },
    );
  }

  Widget _card(BuildContext context, N notifier, T item) {
    final deleted = item.isDeleted;
    return Card(
      child: ListTile(
        onTap: () => onOpen(item),
        leading: Checkbox(
          value: notifier.selected.contains(item.id),
          onChanged: deleted ? null : (_) => notifier.toggleSelection(item.id),
        ),
        title: Text(
          titleOf(item),
          style: deleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          deleted ? 'Удалено · ${subtitleOf(item)}' : subtitleOf(item),
        ),
        trailing: _menu(context, item),
      ),
    );
  }

  void _softDelete(BuildContext context, T item) => _run(
    context,
    '«${titleOf(item)}» удалено',
    () => context.read<N>().softDelete(item.id),
  );

  void _restore(BuildContext context, T item) => _run(
    context,
    'Запись восстановлена',
    () => context.read<N>().restore(item.id),
  );

  Future<void> _hardDelete(BuildContext context, T item) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить навсегда?',
      text: '«${titleOf(item)}» будет стёрто без возможности восстановления.',
    );
    if (ok && context.mounted) {
      await _run(
        context,
        'Запись стёрта',
        () => context.read<N>().hardDelete(item.id),
      );
    }
  }

  /// Кнопки в строке таблицы.
  List<Widget> _actions(BuildContext context, T item) {
    return [
      if (item.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore_from_trash),
          onPressed: () => _restore(context, item),
        )
      else
        IconButton(
          tooltip: 'Удалить (в корзину)',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _softDelete(context, item),
        ),
      IconButton(
        tooltip: 'Удалить навсегда',
        icon: const Icon(Icons.delete_forever),
        onPressed: () => _hardDelete(context, item),
      ),
    ];
  }

  /// На карточке места мало, поэтому те же действия собраны в меню.
  Widget _menu(BuildContext context, T item) {
    return PopupMenuButton<void Function()>(
      tooltip: 'Действия',
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (item.isDeleted)
          PopupMenuItem(
            value: () => _restore(context, item),
            child: const Text('Восстановить'),
          )
        else
          PopupMenuItem(
            value: () => _softDelete(context, item),
            child: const Text('Удалить'),
          ),
        PopupMenuItem(
          value: () => _hardDelete(context, item),
          child: const Text('Удалить навсегда'),
        ),
      ],
    );
  }
}

/// Выполняет операцию и сообщает результат во всплывающей полосе.
Future<void> _run(
  BuildContext context,
  String done,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String text,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _SelectionBar<T extends Entity, N extends EntityListNotifier<T, Object?>>
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.select<N, int>((n) => n.selected.length);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text('Выбрано: $count')),
          TextButton(
            onPressed: () => context.read<N>().selectPage(false),
            child: const Text('Снять'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Удалить выбранные'),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Удалить выбранные?',
                text:
                    'Будет удалено записей: $count. '
                    'Их можно будет восстановить, включив показ удалённых.',
              );
              if (!ok || !context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final n = await context.read<N>().deleteSelected();
                messenger.showSnackBar(
                  SnackBar(content: Text('Удалено записей: $n')),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final PageResult<Object?> page;
  final bool hasFilters;
  final VoidCallback onReset;
  final VoidCallback onFirstPage;

  const _EmptyView({
    required this.page,
    required this.hasFilters,
    required this.onReset,
    required this.onFirstPage,
  });

  @override
  Widget build(BuildContext context) {
    // Записи есть, но страница за пределами выборки (например, после удаления)
    final beyondEnd = page.total > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            beyondEnd ? 'На этой странице записей нет' : 'Ничего не найдено',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          if (beyondEnd)
            TextButton(
              onPressed: onFirstPage,
              child: const Text('К первой странице'),
            )
          else if (hasFilters)
            TextButton(
              onPressed: onReset,
              child: const Text('Сбросить фильтры'),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
