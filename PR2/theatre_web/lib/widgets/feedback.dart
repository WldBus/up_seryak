import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';

/// Выполняет действие и показывает результат. Если сервер ответил 409
/// (на запись ссылаются или не хватает мест), показываю диалог — сообщение
/// длинное и важное, в снекбаре его легко не заметить.
Future<bool> runWithFeedback(
  BuildContext context,
  String done,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on ConflictException catch (e) {
    if (context.mounted) await showBlockedDialog(context, e.message);
    return false;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    return false;
  }
}

Future<void> showBlockedDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.link),
      title: const Text('Операция невозможна'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String text,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return result ?? false;
}
