import '../models/actor.dart';
import '../models/list_query.dart';
import '../repositories/actor_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class ActorListNotifier extends EntityListNotifier<Actor, ListQuery> {
  /// чтобы в строке актёра показывать название его театра
  final Catalog catalog;

  ActorListNotifier(ActorRepository repository, this.catalog)
    : super(repository, ListQuery(sortFields: Actor.sortFields));

  /// справочники берутся из кэша, заново с сервера не грузятся
  @override
  Future<void> beforeLoad() => catalog.ensureLoaded();

  @override
  Future<Actor?> findById(int id) async {
    await catalog.ensureLoaded();
    return super.findById(id);
  }

  /// актёры поменялись — список труппы в форме спектакля устарел
  @override
  void afterChange() => catalog.invalidate();
}
