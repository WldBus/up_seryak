import '../core/fake_network.dart';
import '../models/genre.dart';
import '../models/list_query.dart';
import 'genre_repository.dart';
import 'local_store.dart';
import 'persistent_repository.dart';
import 'seed.dart';

class PersistentGenreRepository extends PersistentRepository<Genre, ListQuery>
    implements GenreRepository {
  PersistentGenreRepository(FakeNetwork network, LocalStore store)
    : super(
        network: network,
        store: store,
        name: 'genres',
        title: 'Жанры',
        fromJson: Genre.fromJson,
        seed: seedGenres,
      );

  @override
  bool matches(Genre g, ListQuery q) {
    final needle = q.search.trim().toLowerCase();
    return needle.isEmpty ||
        g.name.toLowerCase().contains(needle) ||
        g.description.toLowerCase().contains(needle);
  }

  @override
  int compare(Genre a, Genre b, ListQuery q) => switch (q.sortField) {
    'id' => a.id.compareTo(b.id),
    _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };

  @override
  Map<String, String> uniqueErrors(Genre item) => {
    if (isTaken(item, (o) => o.name.toLowerCase() == item.name.toLowerCase()))
      'name': 'Жанр «${item.name}» уже есть',
  };

  @override
  Genre withId(Genre item, int id) => item.copyWith(id: id);

  @override
  Genre withDeletedAt(Genre item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
