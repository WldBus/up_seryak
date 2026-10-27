import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

/// Сюда отправляет redirect маршрута, если роли этот адрес не положен.
/// Не пустой экран и не падение, а понятное объяснение.
class ForbiddenScreen extends StatelessWidget {
  /// какой адрес пытались открыть
  final String? from;

  const ForbiddenScreen({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthNotifier>().role;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Недостаточно прав', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Роль «${role?.label ?? 'гость'}» не позволяет открыть '
                '${from ?? 'эту страницу'}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Если доступ нужен, обратитесь к администратору.',
                style: TextStyle(color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
