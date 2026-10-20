import '../core/fake_network.dart';
import '../models/actor.dart';
import '../models/list_query.dart';
import 'actor_repository.dart';
import 'local_store.dart';
import 'persistent_repository.dart';
import 'seed.dart';

class PersistentActorRepository extends PersistentRepository<Actor, ListQuery>
    implements ActorRepository {
  PersistentActorRepository(FakeNetwork network, LocalStore store)
    : super(
        network: network,
        store: store,
        name: 'actors',
        title: 'Актёры',
        fromJson: Actor.fromJson,
        seed: seedActors,
      );

  /// ищем по фамилии и стране, как авторов в ТЗ ПР2
  @override
  bool matches(Actor a, ListQuery q) {
    final needle = q.search.trim().toLowerCase();
    return needle.isEmpty ||
        a.lastName.toLowerCase().contains(needle) ||
        a.country.toLowerCase().contains(needle);
  }

  @override
  int compare(Actor a, Actor b, ListQuery q) => switch (q.sortField) {
    'country' => a.country.compareTo(b.country),
    'birthYear' => a.birthYear.compareTo(b.birthYear),
    _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  };

  @override
  Actor withId(Actor item, int id) => item.copyWith(id: id);

  @override
  Actor withDeletedAt(Actor item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
