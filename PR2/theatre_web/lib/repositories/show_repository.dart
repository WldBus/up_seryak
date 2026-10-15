import '../models/show.dart';
import '../models/show_query.dart';
import 'entity_repository.dart';

abstract interface class ShowRepository
    implements EntityRepository<Show, ShowQuery> {}
