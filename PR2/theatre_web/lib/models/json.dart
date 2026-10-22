// Функции для безопасного чтения JSON. Данные приходят с сервера (в ПР3
// брались из localStorage), и там поле может отсутствовать, быть null
// или другого типа. Поэтому везде есть значение по умолчанию, а не просто
// json['field'] as int — от такого приложение падает.

int readInt(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final v = json[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String readString(
  Map<String, dynamic> json,
  String key, [
  String fallback = '',
]) {
  final v = json[key];
  return v is String ? v : (v?.toString() ?? fallback);
}

List<int> readIntList(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is int) e else if (e is num) e.toInt(),
  ];
}

DateTime? readDate(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is String ? DateTime.tryParse(v) : null;
}

Map<String, dynamic> readMap(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is Map<String, dynamic> ? v : const {};
}

/// id связанной записи. На запись сервер принимает `theatreId: 1`,
/// а отдаёт развёрнутый объект `theatre: {id: 1, name: ...}` — понимаю обе формы
int readRefId(Map<String, dynamic> json, String idKey, String objectKey) {
  if (json.containsKey(idKey)) return readInt(json, idKey);
  return readInt(readMap(json, objectKey), 'id');
}

/// то же для списка: `genreIds: [1, 4]` или `genres: [{id: 1, ...}, ...]`
List<int> readRefIds(Map<String, dynamic> json, String idsKey, String listKey) {
  if (json.containsKey(idsKey)) return readIntList(json, idsKey);
  final v = json[listKey];
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is Map<String, dynamic>) readInt(e, 'id'),
  ];
}
