import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/booking.dart';

/// Карточка брони. Кнопки передаёт экран: у зрителя «Продлить»,
/// у кассира «Выкуплена» и «Отменить».
class BookingTile extends StatelessWidget {
  final Booking booking;

  /// показывать ли зрителя (в кассе нужно, в «моих» — нет)
  final bool showSpectator;
  final List<Widget> actions;

  const BookingTile({
    super.key,
    required this.booking,
    this.showSpectator = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (color, icon) = switch (b.status) {
      BookingStatus.active => (scheme.primaryContainer, Icons.schedule),
      BookingStatus.paid => (Colors.green.shade100, Icons.check_circle),
      BookingStatus.cancelled => (scheme.surfaceContainerHighest, Icons.block),
      BookingStatus.expired => (scheme.errorContainer, Icons.timer_off),
    };
    final expires = b.expiresAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.showTitle, style: theme.textTheme.titleMedium),
                ),
                Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(b.status.label),
                  backgroundColor: color,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (showSpectator) b.spectatorName,
                if (b.showDate != null) formatDateTime(b.showDate!),
                'билетов: ${b.seats}',
                formatPrice(b.total),
              ].join(' · '),
            ),
            if (b.isActive && expires != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Бронь держится до ${formatDateTime(expires)}'
                  '${b.extended ? ' (уже продлевали)' : ''}',
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

/// Переключатель статуса над списком броней.
class BookingStatusFilter extends StatelessWidget {
  final BookingStatus? value;
  final ValueChanged<BookingStatus?> onChanged;

  const BookingStatusFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Все'),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final s in BookingStatus.values)
          ChoiceChip(
            label: Text(s.label),
            selected: value == s,
            onSelected: (_) => onChanged(s),
          ),
      ],
    );
  }
}
