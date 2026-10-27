import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/booking.dart';
import '../../state/admin_notifier.dart';

/// «Статистика» — экран только для администратора.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminNotifier>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminNotifier>();
    final s = admin.stats;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: admin.loadStats,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: admin.error != null
          ? Center(child: Text(admin.error!))
          : s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _number(context, 'Выручка', formatPrice(s.revenue)),
                    _number(context, 'Продано билетов', '${s.seatsSold}'),
                    _number(context, 'Спектаклей', '${s.shows}'),
                    _number(context, 'Театров', '${s.theatres}'),
                    _number(context, 'Зрителей', '${s.spectators}'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Бронирования', style: theme.textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final st in BookingStatus.values)
                      Chip(
                        label: Text('${st.label}: ${s.bookings[st.code] ?? 0}'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Пользователи', style: theme.textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Зрители: ${s.users['viewer'] ?? 0}')),
                    Chip(label: Text('Кассиры: ${s.users['cashier'] ?? 0}')),
                    Chip(
                      label: Text('Администраторы: ${s.users['admin'] ?? 0}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Самые продаваемые спектакли',
                  style: theme.textTheme.titleMedium,
                ),
                Card(
                  child: Column(
                    children: [
                      for (final (title, sold, total) in s.topShows)
                        ListTile(
                          title: Text(title),
                          subtitle: LinearProgressIndicator(
                            value: total == 0 ? 0 : sold / total,
                          ),
                          trailing: Text('$sold из $total'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _number(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
