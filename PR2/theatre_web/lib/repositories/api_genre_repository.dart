import '../models/list_query.dart';
import '../models/genre.dart';
import 'api_repository.dart';
import 'genre_repository.dart';

class ApiGenreRepository extends ApiRepository<Genre, ListQuery>
    implements GenreRepository {
  ApiGenreRepository(super.dio)
    : super(path: '/genres', fromJson: Genre.fromJson);

  @override
  Map<String, dynamic> queryOf(ListQuery q) => listQueryParams(q);
}
