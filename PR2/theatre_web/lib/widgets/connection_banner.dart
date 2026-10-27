import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connection_status.dart';

/// Полоса сверху над всеми экранами, пока нет связи с сервером. Без неё
/// при выключенном сервере человек видел бы только пустые списки и не
/// понимал, что происходит.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<ConnectionStatus?>();
    if (status == null || status.online) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          // Wrap, чтобы на узком окне кнопка ушла на вторую строку
          child: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.cloud_off, color: scheme.onErrorContainer),
              Text(
                'Нет связи с сервером. Проверяю каждые 5 секунд — '
                'когда связь появится, данные загрузятся сами.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
              TextButton(
                onPressed: status.check,
                child: const Text('Проверить сейчас'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Обёртка для экрана ошибки: когда связь вернулась, сама вызывает
/// onRetry — как будто человек нажал «Повторить».
class RetryOnReconnect extends StatefulWidget {
  final VoidCallback onRetry;
  final Widget child;

  const RetryOnReconnect({
    super.key,
    required this.onRetry,
    required this.child,
  });

  @override
  State<RetryOnReconnect> createState() => _RetryOnReconnectState();
}

class _RetryOnReconnectState extends State<RetryOnReconnect> {
  ConnectionStatus? _status;
  bool _wasOnline = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // в тестах ConnectionStatus может не быть — тогда просто показываю child
    final status = context.read<ConnectionStatus?>();
    if (status == _status) return;
    _status?.removeListener(_changed);
    _status = status?..addListener(_changed);
    _wasOnline = status?.online ?? true;
  }

  void _changed() {
    final online = _status!.online;
    if (online && !_wasOnline) widget.onRetry();
    _wasOnline = online;
  }

  @override
  void dispose() {
    _status?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
