import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fake_network.dart';

/// Кнопка в шапке: имитирует пропажу сети, чтобы проверить экран ошибки.
class NetworkToggle extends StatelessWidget {
  const NetworkToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.select<FakeNetwork, bool>((n) => n.offline);
    return IconButton(
      tooltip: offline ? 'Сеть отключена (имитация)' : 'Имитировать сбой сети',
      icon: Icon(offline ? Icons.wifi_off : Icons.wifi),
      color: offline ? Theme.of(context).colorScheme.error : null,
      onPressed: () => context.read<FakeNetwork>().toggleOffline(),
    );
  }
}
