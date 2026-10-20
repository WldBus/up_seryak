import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../models/genre.dart';
import '../../state/genre_list_notifier.dart';
import '../../widgets/details_view.dart';

class GenreDetailsScreen extends StatelessWidget {
  final int? id;

  const GenreDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<GenreListNotifier>();
    return DetailsView<Genre>(
      title: 'Жанр',
      backLocation: listLocation('/genres', notifier.query.toParams()),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (g) => g.name,
      editLocation: (g) => '/genres/${g.id}/edit',
      onDelete: (g) => notifier.softDelete(g.id),
      fieldsOf: (g) => [
        ('Описание', g.description.isEmpty ? '—' : g.description),
      ],
    );
  }
}
