import 'query_params.dart';

/// Фильтры для простых списков (театры, актёры, жанры, зрители):
/// поиск, сортировка, страница и показ удалённых. У спектаклей фильтров
/// больше, поэтому у них свой ShowQuery.
///
/// Поля сортировки у каждой сущности свои, поэтому передаю их сюда,
/// но в сравнении они не участвуют.
class ListQuery implements PagedQuery {
  final List<String> sortFields;
  final String search;
  final String sortField;
  @override
  final bool sortAscending;
  @override
  final int page;
  @override
  final int size;
  @override
  final bool includeDeleted;

  ListQuery({
    required this.sortFields,
    this.search = '',
    String? sortField,
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  }) : sortField = sortField ?? sortFields.first;

  bool get hasFilters => search.isNotEmpty;

  ListQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ListQuery(
      sortFields: sortFields,
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      // поменяли фильтры — всегда возвращаемся на первую страницу
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  /// для кнопки «Сбросить»: фильтры по умолчанию, но размер страницы тот же
  ListQuery reset() => ListQuery(sortFields: sortFields, size: size);

  factory ListQuery.fromParams(
    Map<String, String> p, {
    required List<String> sortFields,
  }) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return ListQuery(
      sortFields: sortFields,
      search: p['search']?.trim() ?? '',
      sortField: sortField,
      sortAscending: sortAscending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['deleted'] == 'true',
    );
  }

  Map<String, String> toParams() {
    final params = <String, String>{if (search.isNotEmpty) 'search': search};
    writeCommonParams(
      params,
      sortField: sortField,
      defaultSortField: sortFields.first,
      sortAscending: sortAscending,
      page: page,
      size: size,
      includeDeleted: includeDeleted,
    );
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is ListQuery &&
      other.search == search &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode =>
      Object.hash(search, sortField, sortAscending, page, size, includeDeleted);
}
