import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ввода, которое сообщает об изменении не на каждую букву,
/// а через delay после того, как перестали печатать.
class DebouncedField extends StatefulWidget {
  final String value;
  final String label;
  final IconData? icon;
  final bool numeric;
  final ValueChanged<String> onChanged;
  final Duration delay;

  const DebouncedField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.icon,
    this.numeric = false,
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedField> createState() => _DebouncedFieldState();
}

class _DebouncedFieldState extends State<DebouncedField> {
  late final _controller = TextEditingController(text: widget.value);
  Timer? _timer;

  @override
  void didUpdateWidget(DebouncedField old) {
    super.didUpdateWidget(old);
    // значение поменялось снаружи (нажали «назад» или «Сбросить») — ставим его,
    // но только если человек сейчас не печатает, чтобы не стереть его текст
    final typing = _timer?.isActive ?? false;
    if (!typing && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _changed(String text) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(text.trim()));
  }

  void _submit(String text) {
    _timer?.cancel();
    widget.onChanged(text.trim());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      onSubmitted: _submit,
      keyboardType: widget.numeric ? TextInputType.number : null,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
