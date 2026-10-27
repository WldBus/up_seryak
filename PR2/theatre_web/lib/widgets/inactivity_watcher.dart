import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../state/auth_notifier.dart';

/// Выход по неактивности. Любое действие (мышь, колесо, клавиатура)
/// перезапускает отсчёт. За [inactivityWarning] до выхода сверху появляется
/// предупреждение с обратным отсчётом, по истечении — выход из системы.
///
/// Работает, только пока человек в системе.
class InactivityWatcher extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final Duration warning;

  const InactivityWatcher({
    super.key,
    required this.child,
    this.timeout = inactivityTimeout,
    this.warning = inactivityWarning,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warnTimer;
  Timer? _logoutTimer;
  Timer? _ticker;
  DateTime? _logoutAt;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    // клавиатуру слушаю глобально: у обёртки над всем приложением нет
    // фокуса, и KeyboardListener не узнал бы про набор текста в форме
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  // false — событие не обработано, пусть идёт дальше
  bool _onKey(KeyEvent event) {
    _activity();
    return false;
  }

  void _activity() {
    if (!_active) return;
    context.read<AuthNotifier>().touch();
    _restart();
  }

  void _restart() {
    _cancel();
    final warnAfter = widget.timeout - widget.warning;
    _logoutAt = DateTime.now().add(widget.timeout);
    _warnTimer = Timer(warnAfter, _startCountdown);
    _logoutTimer = Timer(widget.timeout, _timeout);
    if (mounted) setState(() {}); // спрятать предупреждение, если было
  }

  void _startCountdown() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  void _timeout() {
    _cancel();
    final minutes = widget.timeout.inSeconds >= 60
        ? '${widget.timeout.inMinutes} мин'
        : '${widget.timeout.inSeconds} с';
    context.read<AuthNotifier>().logout(
      message: 'Сессия завершена из-за неактивности ($minutes без действий).',
    );
  }

  void _cancel() {
    _warnTimer?.cancel();
    _logoutTimer?.cancel();
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthNotifier, bool>(
      (a) => a.isAuthenticated,
    );
    if (loggedIn != _active) {
      _active = loggedIn;
      if (loggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
      } else {
        _cancel();
      }
    }
    final warning = _active && _ticker != null && _logoutAt != null;
    final left = warning
        ? _logoutAt!.difference(DateTime.now()).inSeconds.clamp(0, 999)
        : 0;

    return Listener(
      // перехват без поглощения: событие идёт дальше к виджетам. иначе
      // ни одна кнопка не нажималась бы
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerMove: (_) => _activity(),
      onPointerHover: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      child: Stack(
        children: [
          widget.child,
          if (warning)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 12),
                        Text('Нет действий. Сессия завершится через $left с'),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _activity,
                          child: const Text('Продолжить работу'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
