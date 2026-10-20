import 'package:flutter/material.dart';

import '../../models/list_query.dart';
import '../../models/theatre.dart';
import '../../state/theatre_list_notifier.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/simple_list_screen.dart';

class TheatreListScreen extends StatelessWidget {
  final ListQuery query;

  const TheatreListScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Theatre, TheatreListNotifier>(
      query: query,
      title: 'Театры',
      path: '/theatres',
      searchLabel: 'Поиск по названию или городу',
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
    );
  }
}
