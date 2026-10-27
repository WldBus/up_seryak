import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/app_user.dart';
import '../models/entity.dart';
import '../models/page_result.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/list_state.dart';
import 'entity_table.dart';
import 'connection_banner.dart';
import 'feedback.dart';
import 'pager_bar.dart';

/// Общий экран списка: фильтры, полоса с выбранными, таблица или карточки
/// (зависит от ширины), страницы и все состояния загрузки. Конкретному
/// экрану остаётся задать фильтры, колонки и подписи.
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

  /// переход в форму редактирования. если null — кнопки «Изменить» нет
  final ValueChanged<T>? onEdit;

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
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();
    // кнопки удаления и выбор строк показываю только тем, кому их разрешено
    // нажимать. это удобство, а не защита: сервер всё равно проверит роль
    final role = context.select<AuthNotifier, Role?>((a) => a.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // на узком окне прячу фильтры в раскрывающуюся панель, а то для списка
        // не остаётся места. открыта она или нет, помнит сам ExpansionTile
        if (screenSizeOf(context) == ScreenSize.compact)
          ExpansionTile(
            leading: const Icon(Icons.tune),
            title: Text(hasFilters ? 'Фильтры (заданы)' : 'Поиск и фильтры'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [filters],
          )
        else
          Padding(padding: const EdgeInsets.all(12), child: filters),
        if (notifier.hasSelection && canEditCatalog(role))
          _SelectionBar<T, N>(),
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
            ListLoaded(page: final p) => _buildItems(
              context,
              notifier,
              p,
              role,
            ),
          },
        ),
        if (notifier.state case ListLoaded(page: final p) when p.total > 0) ...[
          const Divider(height: 1),
          PagerBar(page: p, onPage: onPage, onSize: onSize),
        ],
      ],
    );
  }

  Widget _buildItems(
    BuildContext context,
    N notifier,
    PageResult<T> page,
    Role? role,
  ) {
    final canSelect = canEditCatalog(role);
    final hasActions = canSelect || onEdit != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < cardsBreakpoint) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: page.items.length,
            itemBuilder: (context, i) =>
                _card(context, notifier, page.items[i], role),
          );
        }
        // планшет: те же карточки, но в две колонки
        if (constraints.maxWidth < tableBreakpoint) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 80,
            ),
            itemCount: page.items.length,
            itemBuilder: (context, i) =>
                _card(context, notifier, page.items[i], role),
          );
        }
        return EntityTable<T>(
          columns: columns,
          items: page.items,
          idOf: (e) => e.id,
          selected: notifier.selected,
          onToggleSelect: canSelect ? notifier.toggleSelection : null,
          onSelectAll: canSelect ? notifier.selectPage : null,
          isDisabled: (e) => e.isDeleted,
          onOpen: onOpen,
          sortField: sortField,
          sortAscending: sortAscending,
          onSort: onSort,
          // на 1280 три значка в строке не помещались — до 1200 px
          // доступной ширины кнопки свёрнуты в меню, как на карточке
          actions: !hasActions
              ? null
              : constraints.maxWidth < 1200
              ? (e) => [_menu(context, e, role)]
              : (e) => _actions(context, e, role),
        );
      },
    );
  }

  Widget _card(BuildContext context, N notifier, T item, Role? role) {
    final deleted = item.isDeleted;
    final canSelect = canEditCatalog(role);
    return Card(
      child: ListTile(
        onTap: () => onOpen(item),
        leading: canSelect
            ? Checkbox(
                value: notifier.selected.contains(item.id),
                onChanged: deleted
                    ? null
                    : (_) => notifier.toggleSelection(item.id),
              )
            : null,
        // длинное название обрезаю многоточием, иначе оно раздвигает карточку
        title: Text(
          titleOf(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: deleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          deleted ? 'Удалено · ${subtitleOf(item)}' : subtitleOf(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: canSelect || onEdit != null
            ? _menu(context, item, role)
            : null,
      ),
    );
  }

  void _softDelete(BuildContext context, T item) => runWithFeedback(
    context,
    '«${titleOf(item)}» удалено',
    () => context.read<N>().softDelete(item.id),
  );

  void _restore(BuildContext context, T item) => runWithFeedback(
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
      await runWithFeedback(
        context,
        'Запись стёрта',
        () => context.read<N>().hardDelete(item.id),
      );
    }
  }

  /// кнопки в строке таблицы
  List<Widget> _actions(BuildContext context, T item, Role? role) {
    return [
      if (onEdit != null && !item.isDeleted)
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => onEdit!(item),
        ),
      if (item.isDeleted && canRestore(role))
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore_from_trash),
          onPressed: () => _restore(context, item),
        )
      else if (!item.isDeleted && canEditCatalog(role))
        IconButton(
          tooltip: 'Удалить (в корзину)',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _softDelete(context, item),
        ),
      if (canHardDelete(role))
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever),
          onPressed: () => _hardDelete(context, item),
        ),
    ];
  }

  /// на карточке мало места, поэтому кнопки убрал в меню
  Widget _menu(BuildContext context, T item, Role? role) {
    return PopupMenuButton<void Function()>(
      tooltip: 'Действия',
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (onEdit != null && !item.isDeleted)
          PopupMenuItem(
            value: () => onEdit!(item),
            child: const Text('Изменить'),
          ),
        if (item.isDeleted && canRestore(role))
          PopupMenuItem(
            value: () => _restore(context, item),
            child: const Text('Восстановить'),
          )
        else if (!item.isDeleted && canEditCatalog(role))
          PopupMenuItem(
            value: () => _softDelete(context, item),
            child: const Text('Удалить'),
          ),
        if (canHardDelete(role))
          PopupMenuItem(
            value: () => _hardDelete(context, item),
            child: const Text('Удалить навсегда'),
          ),
      ],
    );
  }
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
              await runWithFeedback(
                context,
                'Удалено записей: $count',
                context.read<N>().deleteSelected,
              );
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
    // записи вообще есть, просто эта страница пустая (например, после удаления)
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
    // связь вернулась — повторяю загрузку сам, без нажатия на кнопку
    return RetryOnReconnect(
      onRetry: onRetry,
      child: Center(
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
      ),
    );
  }
}
