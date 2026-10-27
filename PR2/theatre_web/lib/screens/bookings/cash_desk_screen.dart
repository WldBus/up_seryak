import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions.dart';
import '../../models/booking.dart';
import '../../state/auth_notifier.dart';
import '../../state/bookings_notifier.dart';
import '../../state/list_state.dart';
import '../../widgets/debounced_field.dart';
import '../../widgets/feedback.dart';
import 'booking_tile.dart';

/// «Касса» — экран только для кассира: все брони, выкуп и отмена.
/// Новая бронь оформляется из карточки спектакля.
class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({super.key});

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // в кассе по умолчанию нужны действующие брони
      context.read<BookingsNotifier>().setStatus(BookingStatus.active);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookingsNotifier>();
    final canClose = context.watch<AuthNotifier>().can(canUseCashDesk);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Касса'),
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
          Text(
            'Новая бронь оформляется из карточки спектакля — кнопка '
            '«Забронировать». Здесь брони выкупают или отменяют.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: DebouncedField(
                  value: notifier.search,
                  label: 'Поиск по зрителю или спектаклю',
                  icon: Icons.search,
                  onChanged: notifier.setSearch,
                ),
              ),
              BookingStatusFilter(
                value: notifier.status,
                onChanged: notifier.setStatus,
              ),
            ],
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
                child: Center(child: Text('Бронирований не найдено')),
              ),
            ],
            ListLoaded(page: final p) => [
              Text('Найдено: ${p.total}'),
              const SizedBox(height: 8),
              for (final b in p.items)
                BookingTile(
                  booking: b,
                  showSpectator: true,
                  actions: [
                    if (canClose && b.isActive) ...[
                      FilledButton.icon(
                        onPressed: () => _close(b, paid: true),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Выкуплена'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _close(b, paid: false),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Отменить бронь'),
                      ),
                    ],
                  ],
                ),
            ],
          },
        ],
      ),
    );
  }

  Future<void> _close(Booking b, {required bool paid}) async {
    if (!paid) {
      final ok = await confirmDialog(
        context,
        title: 'Отменить бронь?',
        text:
            '${b.spectatorName}, «${b.showTitle}», билетов: ${b.seats}. '
            'Места вернутся в продажу.',
      );
      if (!ok || !mounted) return;
    }
    await runWithFeedback(
      context,
      paid ? 'Бронь выкуплена' : 'Бронь отменена',
      () => context.read<BookingsNotifier>().close(b.id, paid: paid),
    );
  }
}
