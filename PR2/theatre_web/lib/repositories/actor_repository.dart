import '../models/actor.dart';
import '../models/list_query.dart';
import 'entity_repository.dart';

abstract interface class ActorRepository
    implements EntityRepository<Actor, ListQuery> {}
