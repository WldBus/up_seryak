import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/router.dart';
import '../../models/spectator.dart';
import '../../state/spectator_list_notifier.dart';
import '../../widgets/details_view.dart';

class SpectatorDetailsScreen extends StatelessWidget {
  final int? id;

  const SpectatorDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<SpectatorListNotifier>();
    return DetailsView<Spectator>(
      title: 'Зритель',
      backLocation: listLocation('/spectators', notifier.query.toParams()),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (s) => s.fullName,
      editLocation: (s) => '/spectators/${s.id}/edit',
      onDelete: (s) => notifier.softDelete(s.id),
      fieldsOf: (s) => [
        ('Почта', s.email),
        ('Телефон', s.phone),
        ('Карта зрителя', '№ ${s.card.number}'),
        ('Выдана', formatDate(s.card.issuedAt)),
        ('Скидка по карте', '${s.card.discount} %'),
      ],
    );
  }
}
