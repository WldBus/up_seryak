import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../models/app_user.dart';
import '../state/auth_notifier.dart';

/// Главная. У каждой роли свой набор разделов и свой список прав —
/// различия видны сразу после входа.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// разделы по ролям: значок, название, описание, адрес
  static List<(IconData, String, String, String)> _sections(Role role) =>
      switch (role) {
        Role.viewer => [
          (
            Icons.confirmation_number_outlined,
            'Мои бронирования',
            'Ваши брони, срок и продление',
            '/my-bookings',
          ),
          (
            Icons.theater_comedy,
            'Афиша',
            'Спектакли, даты и свободные места',
            '/shows',
          ),
          (Icons.account_balance, 'Театры', 'Где идут спектакли', '/theatres'),
        ],
        Role.cashier => [
          (
            Icons.point_of_sale,
            'Касса',
            'Все брони: выкуп и отмена',
            '/cash-desk',
          ),
          (
            Icons.theater_comedy,
            'Спектакли',
            'Афиша, бронирование, правка',
            '/shows',
          ),
          (Icons.badge, 'Зрители', 'Карточки зрителей', '/spectators'),
          (Icons.category, 'Справочники', 'Театры, актёры, жанры', '/genres'),
        ],
        Role.admin => [
          (
            Icons.manage_accounts,
            'Пользователи',
            'Учётные записи и роли',
            '/users',
          ),
          (Icons.bar_chart, 'Статистика', 'Продажи и брони', '/stats'),
          (
            Icons.restore_from_trash,
            'Удалённые спектакли',
            'Восстановление и удаление навсегда',
            '/shows?deleted=true',
          ),
          (Icons.theater_comedy, 'Спектакли', 'Каталог', '/shows'),
        ],
      };

  /// что проверяется в core/permissions.dart — список для текущей роли
  static const _rights = <(String, bool Function(Role?))>[
    ('Просмотр афиши и справочников', canViewCatalog),
    ('Мои бронирования и продление брони', canSeeOwnBookings),
    ('Правка спектаклей и справочников', canEditCatalog),
    ('Работа со зрителями', canManageSpectators),
    ('Касса: оформление, выкуп и отмена броней', canUseCashDesk),
    ('Восстановление и удаление навсегда', canHardDelete),
    ('Пользователи и роли', canManageUsers),
    ('Статистика', canSeeStats),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Здравствуйте, ${user.fullName}!',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.verified_user, size: 18),
                label: Text(user.role.label),
              ),
              const SizedBox(width: 8),
              Text(
                'вход: ${user.username}',
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (icon, title, text, location) in _sections(user.role))
                SizedBox(
                  width: 260,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go(location),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              text,
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Что доступно вашей роли', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final (text, check) in _rights)
                  ListTile(
                    dense: true,
                    leading: check(user.role)
                        ? Icon(Icons.check_circle, color: Colors.green.shade700)
                        : Icon(Icons.block, color: theme.hintColor),
                    title: Text(text),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Права здесь только для удобства: лишние кнопки скрыты. '
            'Решение о каждой операции принимает сервер.',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
