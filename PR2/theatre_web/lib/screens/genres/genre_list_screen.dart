import 'package:flutter/material.dart';

import '../../models/genre.dart';
import '../../models/list_query.dart';
import '../../state/genre_list_notifier.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/simple_list_screen.dart';

class GenreListScreen extends StatelessWidget {
  final ListQuery query;

  const GenreListScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Genre, GenreListNotifier>(
      query: query,
      title: 'Жанры',
      path: '/genres',
      searchLabel: 'Поиск по названию или описанию',
      titleOf: (g) => g.name,
      subtitleOf: (g) => g.description,
      columns: [
        TableColumnSpec(
          label: '№',
          sortField: 'id',
          numeric: true,
          build: (g) => Text('${g.id}'),
        ),
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (g) => Text(g.name),
        ),
        TableColumnSpec(label: 'Описание', build: (g) => Text(g.description)),
      ],
    );
  }
}
