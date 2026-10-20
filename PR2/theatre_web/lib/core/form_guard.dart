import 'package:flutter/material.dart';

/// Следит, есть ли в открытой форме несохранённые изменения.
/// Форма ставит dirty = true, а в router.dart перед уходом с формы
/// (назад, пункт меню, «Отмена») вызывается confirmLeave.
class FormGuard {
  bool dirty = false;

  /// true — можно уходить. Если ничего не меняли, просто уходим без вопроса
  Future<bool> confirmLeave(BuildContext context) async {
    if (!dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Уйти без сохранения?'),
        content: const Text('Введённые изменения будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );
    if (leave == true) dirty = false;
    return leave == true;
  }
}
