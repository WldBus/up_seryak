import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/actor.dart';
import '../../models/list_query.dart';
import '../../state/actor_list_notifier.dart';
import '../../state/catalog.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/simple_list_screen.dart';

class ActorListScreen extends StatelessWidget {
  final ListQuery query;

  const ActorListScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<Catalog>();
    return SimpleListScreen<Actor, ActorListNotifier>(
      query: query,
      title: 'Актёры',
      path: '/actors',
      searchLabel: 'Поиск по фамилии или стране',
      titleOf: (a) => a.fullName,
      subtitleOf: (a) =>
          '${catalog.theatreName(a.theatreId)} · ${a.country}, ${a.birthYear}',
      columns: [
        TableColumnSpec(
          label: 'Фамилия и имя',
          sortField: 'lastName',
          build: (a) => Text(a.fullName),
        ),
        TableColumnSpec(
          label: 'Страна',
          sortField: 'country',
          build: (a) => Text(a.country),
        ),
        TableColumnSpec(
          label: 'Год рождения',
          sortField: 'birthYear',
          numeric: true,
          build: (a) => Text('${a.birthYear}'),
        ),
        TableColumnSpec(
          label: 'Театр (труппа)',
          build: (a) => Text(catalog.theatreName(a.theatreId)),
        ),
      ],
    );
  }
}
