import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage_notice.dart';

/// Работа с shared_preferences. В браузере это localStorage, там данные
/// лежат строками JSON под ключами вроде flutter.shows_v2.
///
/// Версия формата прямо в имени ключа. Если поменяю поля моделей —
/// подниму версию: старые данные новым кодом уже не прочитать, поэтому
/// они удаляются и показывается сообщение.
class LocalStore {
  /// версия формата данных. 1 — старые модели без актёров и зрителей
  /// (как в ПР2), 2 — модели ПР3
  static const dataVersion = 2;
  static const _versionKey = 'data_version';

  final SharedPreferences prefs;
  final StorageNotice notice;

  LocalStore(this.prefs, this.notice) {
    _migrate();
  }

  String keyOf(String name) => '${name}_v$dataVersion';

  void _migrate() {
    final stored = prefs.getInt(_versionKey);
    final oldKeys = prefs
        .getKeys()
        .where((k) => RegExp(r'_v\d+$').hasMatch(k))
        .where((k) => !k.endsWith('_v$dataVersion'))
        .toList();

    if (oldKeys.isNotEmpty || (stored != null && stored != dataVersion)) {
      for (final k in oldKeys) {
        prefs.remove(k);
      }
      notice.add(
        'Найдены сохранённые данные старого формата (версия ${stored ?? 1}). '
        'Они несовместимы с текущей версией $dataVersion и удалены. '
        'Разделы без данных заполнены начальным набором.',
      );
    }
    prefs.setInt(_versionKey, dataVersion);
  }

  /// читает список записей. null — если данных ещё нет (первый запуск),
  /// FormatException — если данные битые
  List<Map<String, dynamic>>? read(String name) {
    final raw = prefs.getString(keyOf(name));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('ожидался список');
    return [
      for (final e in decoded)
        if (e is Map<String, dynamic>)
          e
        else
          throw const FormatException('ожидался объект'),
    ];
  }

  Future<void> write(String name, List<Map<String, dynamic>> rows) =>
      prefs.setString(keyOf(name), jsonEncode(rows));
}
