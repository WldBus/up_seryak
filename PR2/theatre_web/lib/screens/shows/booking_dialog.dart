import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/validators.dart';
import '../../models/show.dart';
import '../../models/spectator.dart';
import '../../state/show_list_notifier.dart';

/// Окно бронирования билетов. true — забронировали.
///
/// Свободные места тут нарочно не проверяю: это делает сервер, и если
/// мест не хватает, он отвечает 409 — сообщение показывается прямо в окне.
Future<bool> showBookingDialog(BuildContext context, Show show) async {
  final booked = await showDialog<bool>(
    context: context,
    builder: (_) => _BookingDialog(show: show),
  );
  return booked ?? false;
}

class _BookingDialog extends StatefulWidget {
  final Show show;

  const _BookingDialog({required this.show});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _seats = TextEditingController(text: '1');
  late final Future<List<Spectator>> _spectators = context
      .read<ShowListNotifier>()
      .spectatorsForBooking();
  int? _spectatorId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // пока запрос идёт, кнопка заблокирована — вторую бронь не создать
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ShowListNotifier>().book(
        widget.show.id,
        _spectatorId!,
        int.parse(_seats.text),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      // 409 «свободных мест нет» и любые другие ошибки сервера
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.show;
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.confirmation_number_outlined),
      title: Text('Бронирование: ${show.title}'),
      content: SizedBox(
        width: 400,
        child: FutureBuilder<List<Spectator>>(
          future: _spectators,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Text('Не удалось загрузить зрителей: ${snap.error}');
            }
            return Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Свободно мест: ${show.seatsAvailable} из ${show.seatsTotal}',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _spectatorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Зритель',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in snap.data!)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.fullName} (карта ${s.card.number})'),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _spectatorId = v),
                    validator: (v) => v == null ? 'Выберите зрителя' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _seats,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Билетов',
                      helperText: 'От 1 до 10',
                      border: OutlineInputBorder(),
                    ),
                    validator: V.combine([
                      V.required('Укажите число билетов'),
                      V.integer(min: 1, max: 10),
                    ]),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Забронировать'),
        ),
      ],
    );
  }
}
