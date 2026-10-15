import 'query_params.dart';

/// Все условия отбора списка спектаклей в одном неизменяемом объекте.
class ShowQuery implements PagedQuery {
  static const sortFields = ['title', 'date', 'price', 'duration'];

  final String search;
  final int? genreId;
  final int? theatreId;
  final int? priceFrom;
  final int? priceTo;
  final String sortField;
  @override
  final bool sortAscending;
  @override
  final int page;
  @override
  final int size;
  @override
  final bool includeDeleted;

  const ShowQuery({
    this.search = '',
    this.genreId,
    this.theatreId,
    this.priceFrom,
    this.priceTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  bool get hasFilters =>
      search.isNotEmpty ||
      genreId != null ||
      theatreId != null ||
      priceFrom != null ||
      priceTo != null;

  ShowQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? theatreId = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ShowQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      theatreId: theatreId == _unset ? this.theatreId : theatreId as int?,
      priceFrom: priceFrom == _unset ? this.priceFrom : priceFrom as int?,
      priceTo: priceTo == _unset ? this.priceTo : priceTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      // Любое изменение условий отбора возвращает на первую страницу
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  /// `_unset` отличает «параметр не передан» от «передан null — сбросить».
  static const _unset = Object();

  factory ShowQuery.fromParams(Map<String, String> p) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return ShowQuery(
      search: p['search']?.trim() ?? '',
      genreId: parseIntParam(p['genreId']),
      theatreId: parseIntParam(p['theatreId']),
      priceFrom: parseIntParam(p['priceFrom']),
      priceTo: parseIntParam(p['priceTo']),
      sortField: sortField,
      sortAscending: sortAscending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['deleted'] == 'true',
    );
  }

  Map<String, String> toParams() {
    final params = <String, String>{
      if (search.isNotEmpty) 'search': search,
      if (genreId != null) 'genreId': '$genreId',
      if (theatreId != null) 'theatreId': '$theatreId',
      if (priceFrom != null) 'priceFrom': '$priceFrom',
      if (priceTo != null) 'priceTo': '$priceTo',
    };
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
      other is ShowQuery &&
      other.search == search &&
      other.genreId == genreId &&
      other.theatreId == theatreId &&
      other.priceFrom == priceFrom &&
      other.priceTo == priceTo &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(
    search,
    genreId,
    theatreId,
    priceFrom,
    priceTo,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
