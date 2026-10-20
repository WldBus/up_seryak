import '../core/fake_network.dart';
import '../models/list_query.dart';
import '../models/spectator.dart';
import 'local_store.dart';
import 'persistent_repository.dart';
import 'seed.dart';
import 'spectator_repository.dart';

class PersistentSpectatorRepository
    extends PersistentRepository<Spectator, ListQuery>
    implements SpectatorRepository {
  PersistentSpectatorRepository(FakeNetwork network, LocalStore store)
    : super(
        network: network,
        store: store,
        name: 'spectators',
        title: 'Зрители',
        fromJson: Spectator.fromJson,
        seed: seedSpectators,
      );

  @override
  bool matches(Spectator s, ListQuery q) {
    final needle = q.search.trim().toLowerCase();
    return needle.isEmpty ||
        s.fullName.toLowerCase().contains(needle) ||
        s.email.toLowerCase().contains(needle) ||
        s.card.number.contains(needle);
  }

  @override
  int compare(Spectator a, Spectator b, ListQuery q) => switch (q.sortField) {
    'email' => a.email.compareTo(b.email),
    'discount' => a.card.discount.compareTo(b.card.discount),
    _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  };

  /// почта и номер карты должны быть уникальными. ключ card.number —
  /// это поле из группы «Карта зрителя» в форме
  @override
  Map<String, String> uniqueErrors(Spectator item) => {
    if (isTaken(item, (o) => o.email.toLowerCase() == item.email.toLowerCase()))
      'email': 'Зритель с почтой ${item.email} уже зарегистрирован',
    if (isTaken(item, (o) => o.card.number == item.card.number))
      'card.number': 'Карта с номером ${item.card.number} уже выдана',
  };

  @override
  Spectator withId(Spectator item, int id) => item.copyWith(id: id);

  @override
  Spectator withDeletedAt(Spectator item, DateTime? deletedAt) =>
      deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);
}
