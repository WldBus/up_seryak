import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/router.dart';
import '../models/theatre.dart';
import '../state/theatre_list_notifier.dart';
import '../widgets/details_view.dart';

class TheatreDetailsScreen extends StatelessWidget {
  final int? id;

  const TheatreDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TheatreListNotifier>();
    return DetailsView<Theatre>(
      title: 'Театр',
      backLocation: theatresLocation(notifier.query),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (t) => t.name,
      fieldsOf: (t) => [
        ('Город', t.city),
        ('Адрес', t.address),
        ('Мест в зале', '${t.hallSeats}'),
        ('Год основания', '${t.founded}'),
      ],
    );
  }
}
