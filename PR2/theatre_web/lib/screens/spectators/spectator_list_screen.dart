import 'package:flutter/material.dart';

import '../../models/list_query.dart';
import '../../models/spectator.dart';
import '../../state/spectator_list_notifier.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/simple_list_screen.dart';

class SpectatorListScreen extends StatelessWidget {
  final ListQuery query;

  const SpectatorListScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Spectator, SpectatorListNotifier>(
      query: query,
      title: 'Зрители',
      path: '/spectators',
      searchLabel: 'Поиск по имени, почте или карте',
      titleOf: (s) => s.fullName,
      subtitleOf: (s) => '${s.email} · карта ${s.card.number}',
      columns: [
        TableColumnSpec(
          label: 'Фамилия и имя',
          sortField: 'lastName',
          build: (s) => Text(s.fullName),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (s) => Text(s.email),
        ),
        TableColumnSpec(label: 'Телефон', build: (s) => Text(s.phone)),
        TableColumnSpec(label: 'Карта', build: (s) => Text(s.card.number)),
        TableColumnSpec(
          label: 'Скидка',
          sortField: 'discount',
          numeric: true,
          build: (s) => Text('${s.card.discount} %'),
        ),
      ],
    );
  }
}
