import '../core/fake_network.dart';
import '../models/show.dart';
import '../models/show_query.dart';
import 'in_memory_repository.dart';
import 'seed.dart';
import 'show_repository.dart';

class InMemoryShowRepository extends InMemoryRepository<Show, ShowQuery>
    implements ShowRepository {
  InMemoryShowRepository(FakeNetwork network) : super(network, seedShows);

  @override
  bool matches(Show s, ShowQuery q) {
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty &&
        !s.title.toLowerCase().contains(needle) &&
        !s.code.toLowerCase().contains(needle)) {
      return false;
    }
    if (q.genreId != null && !s.genreIds.contains(q.genreId)) return false;
    if (q.theatreId != null && s.theatreId != q.theatreId) return false;
    if (q.priceFrom != null && s.price < q.priceFrom!) return false;
    if (q.priceTo != null && s.price > q.priceTo!) return false;
    return true;
  }

  @override
  int compare(Show a, Show b, ShowQuery q) => switch (q.sortField) {
    'date' => a.date.compareTo(b.date),
    'price' => a.price.compareTo(b.price),
    'duration' => a.duration.compareTo(b.duration),
    _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };

  @override
  Show withId(Show item, int id) => item.copyWith(id: id);

  @override
  Show withDeletedAt(Show item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
