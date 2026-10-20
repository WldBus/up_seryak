import '../models/list_query.dart';
import '../models/spectator.dart';
import '../repositories/spectator_repository.dart';
import 'entity_list_notifier.dart';

class SpectatorListNotifier extends EntityListNotifier<Spectator, ListQuery> {
  SpectatorListNotifier(SpectatorRepository repository)
    : super(repository, ListQuery(sortFields: Spectator.sortFields));
}
