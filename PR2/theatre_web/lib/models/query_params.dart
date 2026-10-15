// Помощники для разбора параметров адреса. Адрес может ввести или
// испортить сам пользователь, поэтому всё неверное заменяется значением
// по умолчанию, а не приводит к ошибке.

const pageSizes = [10, 25, 50];

int? parseIntParam(String? value) =>
    value == null ? null : int.tryParse(value.trim());

int parsePage(String? value) {
  final page = parseIntParam(value);
  return page == null || page < 1 ? 1 : page;
}

int parseSize(String? value) {
  final size = parseIntParam(value);
  return pageSizes.contains(size) ? size! : pageSizes.first;
}

/// Разбирает `sort=date,desc`. Возвращает поле и направление.
(String, bool) parseSort(String? value, List<String> allowed) {
  final parts = (value ?? '').split(',');
  final field = allowed.contains(parts.first) ? parts.first : allowed.first;
  final ascending = parts.length < 2 || parts[1] != 'desc';
  return (field, ascending);
}

/// Общие для всех списков параметры: сортировка, страница, удалённые.
/// Значения по умолчанию в адрес не пишутся, чтобы он оставался коротким.
void writeCommonParams(
  Map<String, String> params, {
  required String sortField,
  required String defaultSortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
}) {
  if (sortField != defaultSortField || !sortAscending) {
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
  }
  if (page != 1) params['page'] = '$page';
  if (size != pageSizes.first) params['size'] = '$size';
  if (includeDeleted) params['deleted'] = 'true';
}

/// То, что нужно репозиторию для постраничной выборки любого списка.
abstract interface class PagedQuery {
  bool get sortAscending;
  int get page;
  int get size;
  bool get includeDeleted;
}
