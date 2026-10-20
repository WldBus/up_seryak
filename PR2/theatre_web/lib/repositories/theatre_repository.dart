import '../models/list_query.dart';
import '../models/theatre.dart';
import 'entity_repository.dart';

abstract interface class TheatreRepository
    implements EntityRepository<Theatre, ListQuery> {}
