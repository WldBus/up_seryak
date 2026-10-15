import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/router.dart';
import '../models/genre.dart';
import '../models/show.dart';
import '../state/show_list_notifier.dart';
import '../widgets/details_view.dart';

class ShowDetailsScreen extends StatelessWidget {
  final int? id;

  const ShowDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ShowListNotifier>();
    return DetailsView<Show>(
      title: 'Спектакль',
      backLocation: showsLocation(notifier.query),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (s) => s.title,
      fieldsOf: (s) => [
        ('Код', s.code),
        ('Театр', notifier.theatreName(s.theatreId)),
        ('Жанр', s.genreIds.map(genreName).join(', ')),
        ('Дата и время', formatDateTime(s.date)),
        ('Длительность', formatDuration(s.duration)),
        ('Цена билета', formatPrice(s.price)),
        ('Свободно мест', '${s.seatsAvailable} из ${s.seatsTotal}'),
      ],
    );
  }
}
