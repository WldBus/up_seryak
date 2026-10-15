import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/entity.dart';
import 'network_toggle.dart';

/// Карточка записи: загрузка по идентификатору и таблица «поле — значение».
class DetailsView<T extends Entity> extends StatefulWidget {
  final String title;
  final String backLocation;
  final Future<T?> Function() load;
  final String Function(T item) headingOf;
  final List<(String, String)> Function(T item) fieldsOf;

  const DetailsView({
    super.key,
    required this.title,
    required this.backLocation,
    required this.load,
    required this.headingOf,
    required this.fieldsOf,
  });

  @override
  State<DetailsView<T>> createState() => _DetailsViewState<T>();
}

class _DetailsViewState<T extends Entity> extends State<DetailsView<T>> {
  // Запрос создаётся один раз, а не в build: иначе каждая перерисовка
  // запускала бы загрузку заново
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
