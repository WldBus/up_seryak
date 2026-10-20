import '../models/actor.dart';
import '../models/list_query.dart';
import '../repositories/actor_repository.dart';
import '../repositories/show_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class ActorListNotifier extends EntityListNotifier<Actor, ListQuery> {
  final ShowRepository _shows;

  /// чтобы в строке актёра показывать название его театра
  final Catalog catalog;

  ActorListNotifier(ActorRepository repository, this._shows, this.catalog)
    : super(repository, ListQuery(sortFields: Actor.sortFields));

  @override
  Future<void> beforeLoad() => catalog.refresh();

  @override
  Future<Actor?> findById(int id) async {
    await catalog.ensureLoaded();
    return super.findById(id);
  }

  @override
  Future<String?> deleteBlockReason(int id) async {
    final count = (await _shows.findAll())
        .where((s) => s.actorIds.contains(id))
        .length;
    if (count == 0) return null;
    final actor = await repository.findById(id);
    return 'Актёра «${actor?.fullName ?? id}» нельзя удалить: он занят '
        'в спектаклях ($count).';
  }
}
