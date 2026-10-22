import '../models/list_query.dart';
import '../models/spectator.dart';
import 'api_repository.dart';
import 'spectator_repository.dart';

class ApiSpectatorRepository extends ApiRepository<Spectator, ListQuery>
    implements SpectatorRepository {
  ApiSpectatorRepository(super.dio)
    : super(path: '/spectators', fromJson: Spectator.fromJson);

  @override
  Map<String, dynamic> queryOf(ListQuery q) => listQueryParams(q);
}
