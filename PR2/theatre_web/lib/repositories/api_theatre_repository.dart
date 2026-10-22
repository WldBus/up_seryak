import '../models/list_query.dart';
import '../models/theatre.dart';
import 'api_repository.dart';
import 'theatre_repository.dart';

class ApiTheatreRepository extends ApiRepository<Theatre, ListQuery>
    implements TheatreRepository {
  ApiTheatreRepository(super.dio)
    : super(path: '/theatres', fromJson: Theatre.fromJson);

  @override
  Map<String, dynamic> queryOf(ListQuery q) => listQueryParams(q);
}
