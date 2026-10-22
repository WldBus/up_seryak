import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_test_mode.dart';

/// Кнопка в шапке: учебный режим запросов к серверу. Можно включить
/// задержку (видно индикатор загрузки) или ошибку 500 (видно экран ошибки).
class NetworkToggle extends StatelessWidget {
  const NetworkToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ApiTestMode, ApiMode>((m) => m.mode);
    final error = Theme.of(context).colorScheme.error;
    return PopupMenuButton<ApiMode>(
      tooltip: 'Учебный режим запросов: ${mode.label}',
      initialValue: mode,
      icon: switch (mode) {
        ApiMode.normal => const Icon(Icons.wifi),
        ApiMode.slow => const Icon(Icons.hourglass_bottom),
        ApiMode.fail => Icon(Icons.cloud_off, color: error),
      },
      onSelected: (m) => context.read<ApiTestMode>().mode = m,
      itemBuilder: (_) => [
        for (final m in ApiMode.values)
          CheckedPopupMenuItem(
            value: m,
            checked: m == mode,
            child: Text(m.label),
          ),
      ],
    );
  }
}
