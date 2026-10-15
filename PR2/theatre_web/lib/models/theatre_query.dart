import 'query_params.dart';

/// Условия отбора списка театров. Поиск идёт по названию и городу.
class TheatreQuery implements PagedQuery {
  static const sortFields = ['name', 'city', 'hallSeats', 'founded'];

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

  const TheatreQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  bool get hasFilters => search.isNotEmpty;

  TheatreQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return TheatreQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory TheatreQuery.fromParams(Map<String, String> p) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return TheatreQuery(
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
      other is TheatreQuery &&
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
