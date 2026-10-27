import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions.dart';
import '../../models/booking.dart';
import '../../state/auth_notifier.dart';
import '../../state/bookings_notifier.dart';
import '../../state/list_state.dart';
import '../../widgets/feedback.dart';
import 'booking_tile.dart';

/// «Мои бронирования» — экран только для зрителя. Сервер сам отдаёт
/// зрителю только его брони: даже если подменить запрос, чужих не будет.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingsNotifier>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookingsNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canExtend = auth.can(canExtendBooking);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.user?.spectatorId == null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  'Учётная запись не привязана к карточке зрителя, '
                  'поэтому бронирований нет. Брони оформляются в кассе.',
                ),
              ),
            ),
          Text(
            'Бронь держится 3 дня. Продлить её можно один раз — ещё на 3 дня.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          BookingStatusFilter(
            value: notifier.status,
            onChanged: notifier.setStatus,
          ),
          const SizedBox(height: 12),
          ...switch (notifier.state) {
            ListLoading() => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            ListFailed(message: final m) => [
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(m),
                trailing: TextButton(
                  onPressed: notifier.load,
                  child: const Text('Повторить'),
                ),
              ),
            ],
            ListLoaded(page: final p) when p.items.isEmpty => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Бронирований нет')),
              ),
            ],
            ListLoaded(page: final p) => [
              for (final b in p.items)
                BookingTile(
                  booking: b,
                  actions: [
                    if (canExtend && b.isActive && !b.extended)
                      FilledButton.tonalIcon(
                        onPressed: () => _extend(b),
                        icon: const Icon(Icons.more_time),
                        label: const Text('Продлить на 3 дня'),
                      ),
                  ],
                ),
            ],
          },
        ],
      ),
    );
  }

  Future<void> _extend(Booking b) => runWithFeedback(
    context,
    'Бронь на «${b.showTitle}» продлена',
    () => context.read<BookingsNotifier>().extend(b.id),
  );
}
