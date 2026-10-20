import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/entity.dart';
import 'feedback.dart';
import 'network_toggle.dart';

/// Карточка записи: грузит её по id и показывает поля списком.
class DetailsView<T extends Entity> extends StatefulWidget {
  final String title;
  final String backLocation;
  final Future<T?> Function() load;
  final String Function(T item) headingOf;
  final List<(String, String)> Function(T item) fieldsOf;

  /// куда переходить по кнопке «Изменить»
  final String Function(T item)? editLocation;

  /// удаление в корзину (может не получиться, если есть связи)
  final Future<void> Function(T item)? onDelete;

  const DetailsView({
    super.key,
    required this.title,
    required this.backLocation,
    required this.load,
    required this.headingOf,
    required this.fieldsOf,
    this.editLocation,
    this.onDelete,
  });

  @override
  State<DetailsView<T>> createState() => _DetailsViewState<T>();
}

class _DetailsViewState<T extends Entity> extends State<DetailsView<T>> {
  // запрос создаю один раз, а не в build, иначе при каждой
  // перерисовке он бы запускался заново
  late Future<T?> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(widget.backLocation)),
        title: Text(widget.title),
        actions: const [NetworkToggle(), SizedBox(width: 8)],
      ),
      body: FutureBuilder<T?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Не удалось загрузить: ${snap.error}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(() => _future = widget.load()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          final item = snap.data;
          if (item == null) {
            return const Center(child: Text('Запись не найдена'));
          }
          return _card(context, item);
        },
      ),
    );
  }

  Widget _card(BuildContext context, T item) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.headingOf(item),
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (item.isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Chip(
                        avatar: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Запись удалена'),
                        backgroundColor: theme.colorScheme.errorContainer,
                      ),
                    ),
                  const SizedBox(height: 16),
                  for (final (label, value) in widget.fieldsOf(item))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 160,
                            child: Text(
                              label,
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ),
                          Expanded(child: Text(value)),
                        ],
                      ),
                    ),
                  if (!item.isDeleted &&
                      (widget.editLocation != null || widget.onDelete != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          if (widget.editLocation != null)
                            FilledButton.icon(
                              onPressed: () =>
                                  context.go(widget.editLocation!(item)),
                              icon: const Icon(Icons.edit),
                              label: const Text('Изменить'),
                            ),
                          if (widget.onDelete != null)
                            OutlinedButton.icon(
                              onPressed: () => _delete(item),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Удалить'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(T item) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      text:
          '«${widget.headingOf(item)}» будет перемещено в удалённые. '
          'Его можно будет восстановить из списка.',
    );
    if (!ok || !mounted) return;
    final done = await runWithFeedback(
      context,
      'Запись удалена',
      () => widget.onDelete!(item),
    );
    if (done && mounted) context.go(widget.backLocation);
  }
}
