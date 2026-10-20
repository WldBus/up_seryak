import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../models/actor.dart';
import '../../state/actor_list_notifier.dart';
import '../../state/catalog.dart';
import '../../widgets/details_view.dart';

class ActorDetailsScreen extends StatelessWidget {
  final int? id;

  const ActorDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ActorListNotifier>();
    final catalog = context.watch<Catalog>();
    return DetailsView<Actor>(
      title: 'Актёр',
      backLocation: listLocation('/actors', notifier.query.toParams()),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (a) => a.fullName,
      editLocation: (a) => '/actors/${a.id}/edit',
      onDelete: (a) => notifier.softDelete(a.id),
      fieldsOf: (a) => [
        ('Страна', a.country),
        ('Год рождения', '${a.birthYear}'),
        ('Театр (труппа)', catalog.theatreName(a.theatreId)),
      ],
    );
  }
}
