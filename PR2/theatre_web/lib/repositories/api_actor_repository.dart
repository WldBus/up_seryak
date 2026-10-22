import '../models/list_query.dart';
import '../models/actor.dart';
import 'api_repository.dart';
import 'actor_repository.dart';

class ApiActorRepository extends ApiRepository<Actor, ListQuery>
    implements ActorRepository {
  ApiActorRepository(super.dio)
    : super(path: '/actors', fromJson: Actor.fromJson);

  @override
  Map<String, dynamic> queryOf(ListQuery q) => listQueryParams(q);
}
