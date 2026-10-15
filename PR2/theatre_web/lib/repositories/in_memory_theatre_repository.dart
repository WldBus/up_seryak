import '../core/fake_network.dart';
import '../models/theatre.dart';
import '../models/theatre_query.dart';
import 'in_memory_repository.dart';
import 'seed.dart';
import 'theatre_repository.dart';

class InMemoryTheatreRepository
    extends InMemoryRepository<Theatre, TheatreQuery>
    implements TheatreRepository {
  InMemoryTheatreRepository(FakeNetwork network) : super(network, seedTheatres);

  @override
  Future<List<Theatre>> findAll() async {
    await network.roundTrip();
    return List.unmodifiable(rows);
  }

  @override
  bool matches(Theatre t, TheatreQuery q) {
    final needle = q.search.trim().toLowerCase();
    return needle.isEmpty ||
        t.name.toLowerCase().contains(needle) ||
        t.city.toLowerCase().contains(needle);
  }

  @override
  int compare(Theatre a, Theatre b, TheatreQuery q) => switch (q.sortField) {
    'city' => a.city.compareTo(b.city),
    'hallSeats' => a.hallSeats.compareTo(b.hallSeats),
    'founded' => a.founded.compareTo(b.founded),
    _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };

  @override
  Theatre withId(Theatre item, int id) => item.copyWith(id: id);

  @override
  Theatre withDeletedAt(Theatre item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
