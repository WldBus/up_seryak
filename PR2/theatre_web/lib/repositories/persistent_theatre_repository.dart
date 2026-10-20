import '../core/fake_network.dart';
import '../models/list_query.dart';
import '../models/theatre.dart';
import 'local_store.dart';
import 'persistent_repository.dart';
import 'seed.dart';
import 'theatre_repository.dart';

class PersistentTheatreRepository
    extends PersistentRepository<Theatre, ListQuery>
    implements TheatreRepository {
  PersistentTheatreRepository(FakeNetwork network, LocalStore store)
    : super(
        network: network,
        store: store,
        name: 'theatres',
        title: 'Театры',
        fromJson: Theatre.fromJson,
        seed: seedTheatres,
      );

  @override
  bool matches(Theatre t, ListQuery q) {
    final needle = q.search.trim().toLowerCase();
    return needle.isEmpty ||
        t.name.toLowerCase().contains(needle) ||
        t.city.toLowerCase().contains(needle);
  }

  @override
  int compare(Theatre a, Theatre b, ListQuery q) => switch (q.sortField) {
    'city' => a.city.compareTo(b.city),
    'hallSeats' => a.hallSeats.compareTo(b.hallSeats),
    'founded' => a.founded.compareTo(b.founded),
    _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };

  /// два театра с одним названием в одном городе — скорее всего
  /// одну и ту же запись ввели два раза
  @override
  Map<String, String> uniqueErrors(Theatre item) => {
    if (isTaken(
      item,
      (o) =>
          o.name.toLowerCase() == item.name.toLowerCase() &&
          o.city.toLowerCase() == item.city.toLowerCase(),
    ))
      'name': 'В городе ${item.city} уже есть театр с таким названием',
  };

  @override
  Theatre withId(Theatre item, int id) => item.copyWith(id: id);

  @override
  Theatre withDeletedAt(Theatre item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
