import '../models/show.dart';
import '../models/show_query.dart';
import 'api_repository.dart';
import 'show_repository.dart';

class ApiShowRepository extends ApiRepository<Show, ShowQuery>
    implements ShowRepository {
  ApiShowRepository(super.dio) : super(path: '/shows', fromJson: Show.fromJson);

  /// поиск, фильтры, сортировку и страницы делает сервер
  @override
  Map<String, dynamic> queryOf(ShowQuery q) => {
    ...listParams(
      search: q.search,
      sortField: q.sortField,
      sortAscending: q.sortAscending,
      page: q.page,
      size: q.size,
      includeDeleted: q.includeDeleted,
    ),
    if (q.genreId != null) 'genreId': q.genreId,
    if (q.theatreId != null) 'theatreId': q.theatreId,
    if (q.priceFrom != null) 'priceFrom': q.priceFrom,
    if (q.priceTo != null) 'priceTo': q.priceTo,
  };
}
