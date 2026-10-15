import '../core/fake_network.dart';
import '../models/entity.dart';
import '../models/page_result.dart';
import '../models/query_params.dart';
import 'entity_repository.dart';

/// Общая часть репозиториев в памяти: хранение, постраничная выборка
/// и оба вида удаления. Наследник описывает только отбор и сортировку.
abstract class InMemoryRepository<T extends Entity, Q extends PagedQuery>
    implements EntityRepository<T, Q> {
  final FakeNetwork network;
  final List<T> rows;
  int _nextId;

  InMemoryRepository(this.network, List<T> seed)
    : rows = [...seed],
      _nextId = seed.length + 1;

  /// Проходит ли запись условия поиска и фильтров.
  bool matches(T item, Q query);

  /// Сравнение двух записей по полю сортировки из запроса (по возрастанию).
  int compare(T a, T b, Q query);

  T withId(T item, int id);

  T withDeletedAt(T item, DateTime? deletedAt);

  @override
  Future<PageResult<T>> find(Q q) async {
    await network.roundTrip();

    final found =
        rows
            .where((r) => q.includeDeleted || !r.isDeleted)
            .where((r) => matches(r, q))
            .toList()
          ..sort(
            (a, b) => q.sortAscending ? compare(a, b, q) : compare(b, a, q),
          );

    final total = found.length;
    final from = (q.page - 1) * q.size;
    // num.clamp вернул бы num, а sublist ждёт int, поэтому границу считаем явно
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <T>[] : found.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<T?> findById(int id) async {
    await network.roundTrip();
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<T> create(T item) async {
    await network.roundTrip();
    final created = withId(item, _nextId++);
    rows.add(created);
    return created;
  }

  @override
  Future<T> update(T item) async {
    await network.roundTrip();
    rows[_indexOf(item.id)] = item;
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    rows[i] = withDeletedAt(rows[i], DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await network.roundTrip();
    rows.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    rows[i] = withDeletedAt(rows[i], null);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await network.roundTrip();
    var count = 0;
    for (final id in ids) {
      // В исходном варианте здесь было `!b[i].isDeleted`: обращение по
      // индексу к самой записи и к переменной i в её же инициализаторе
      final i = rows.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        rows[i] = withDeletedAt(rows[i], DateTime.now());
        count++;
      }
    }
    return count;
  }

  int _indexOf(int id) {
    final i = rows.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Запись $id не найдена');
    return i;
  }
}
