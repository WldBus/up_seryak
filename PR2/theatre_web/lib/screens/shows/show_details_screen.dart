import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/permissions.dart';
import '../../core/router.dart';
import '../../models/show.dart';
import '../../state/auth_notifier.dart';
import '../../state/catalog.dart';
import '../../state/show_list_notifier.dart';
import '../../widgets/details_view.dart';
import 'booking_dialog.dart';

class ShowDetailsScreen extends StatelessWidget {
  final int? id;

  const ShowDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ShowListNotifier>();
    final catalog = context.watch<Catalog>();
    // бронь оформляет кассир, у зрителя и админа кнопки нет
    final canBook = context.watch<AuthNotifier>().can(canUseCashDesk);
    return DetailsView<Show>(
      title: 'Спектакль',
      backLocation: showsLocation(notifier.query),
      load: () async => id == null ? null : notifier.findById(id!),
      headingOf: (s) => s.title,
      editLocation: (s) => '/shows/${s.id}/edit',
      onDelete: (s) => notifier.softDelete(s.id),
      extraActions: (s, reload) => [
        if (canBook)
          FilledButton.tonalIcon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (!await showBookingDialog(context, s)) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Билеты забронированы')),
              );
              reload(); // свободных мест стало меньше
            },
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Забронировать'),
          ),
      ],
      fieldsOf: (s) => [
        ('Код', s.code),
        ('Театр', catalog.theatreName(s.theatreId)),
        ('Жанры', s.genreIds.map(catalog.genreName).join(', ')),
        ('Актёры', s.actorIds.map(catalog.actorName).join(', ')),
        ('Дата и время', formatDateTime(s.date)),
        ('Длительность', formatDuration(s.duration)),
        ('Цена билета', formatPrice(s.price)),
        ('Свободно мест', '${s.seatsAvailable} из ${s.seatsTotal}'),
      ],
    );
  }
}
