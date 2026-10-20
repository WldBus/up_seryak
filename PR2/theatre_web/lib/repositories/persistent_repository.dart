import '../core/fake_network.dart';
import '../models/entity.dart';
import '../models/page_result.dart';
import '../models/query_params.dart';
import 'entity_repository.dart';
import 'exceptions.dart';
import 'local_store.dart';

/// Общий код для всех репозиториев: хранение и сохранение в браузер,
/// страницы, проверка уникальности и оба вида удаления. В наследниках
/// остаётся только поиск, сортировка и что должно быть уникальным.
abstract class PersistentRepository<T extends Entity, Q extends PagedQuery>
    implements EntityRepository<T, Q> {
  final FakeNetwork network;
  final LocalStore store;

  /// имя в хранилище: shows → ключ shows_v2
  final String name;

  /// название раздела для сообщений, например «Спектакли»
  final String title;
  final T Function(Map<String, dynamic> json) fromJson;
  final List<T> rows = [];

  PersistentRepository({
    required this.network,
    required this.store,
    required this.name,
    required this.title,
    required this.fromJson,
    required List<T> seed,
  }) {
    _restore(seed);
  }

  /// подходит ли запись под поиск и фильтры
  bool matches(T item, Q query);

  /// сравнение двух записей по выбранному полю (по возрастанию)
  int compare(T a, T b, Q query);

  T withId(T item, int id);

  T withDeletedAt(T item, DateTime? deletedAt);

  /// что не уникально: поле → текст ошибки. по умолчанию проверок нет
  Map<String, String> uniqueErrors(T item) => const {};

  /// занято ли значение другой записью. саму себя не считаем,
  /// иначе при редактировании запись не прошла бы проверку
  bool isTaken(T item, bool Function(T other) same) =>
      rows.any((other) => other.id != item.id && same(other));

  void _restore(List<T> seed) {
    try {
      final saved = store.read(name);
      if (saved == null) {
        rows.addAll(seed); // первый запуск — берём начальные данные
        _persist();
        return;
      }
      rows.addAll(saved.map(fromJson));
    } catch (_) {
      // данные битые (например, поправили руками в DevTools) —
      // не падаем, а берём начальный набор
      rows
        ..clear()
        ..addAll(seed);
      _persist();
      store.notice.add(
        'Сохранённые данные раздела «$title» повреждены и восстановлены '
        'из начального набора.',
      );
    }
  }

  Future<void> _persist() =>
      store.write(name, [for (final r in rows) r.toJson()]);

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
    // clamp тут не подходит: он возвращает num, а sublist нужен int
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <T>[] : found.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<T>> findAll() async {
    await network.roundTrip();
    return List.unmodifiable(rows);
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
    _checkUnique(item);
    final nextId = rows.fold(0, (m, r) => r.id > m ? r.id : m) + 1;
    final created = withId(item, nextId);
    rows.add(created);
    await _persist();
    return created;
  }

  @override
  Future<T> update(T item) async {
    await network.roundTrip();
    _checkUnique(item);
    rows[_indexOf(item.id)] = item;
    await _persist();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    rows[i] = withDeletedAt(rows[i], DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await network.roundTrip();
    rows.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    rows[i] = withDeletedAt(rows[i], null);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await network.roundTrip();
    var count = 0;
    for (final id in ids) {
      // в коде из ТЗ ПР2 тут было !b[i].isDeleted — b это сама запись,
      // а не список, и i используется внутри своего же объявления
      final i = rows.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        rows[i] = withDeletedAt(rows[i], DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  void _checkUnique(T item) {
    final errors = uniqueErrors(item);
    if (errors.isNotEmpty) throw ValidationException(errors);
  }

  int _indexOf(int id) {
    final i = rows.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Запись $id не найдена');
    return i;
  }
}
