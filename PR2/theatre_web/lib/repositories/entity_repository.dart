import '../models/entity.dart';
import '../models/page_result.dart';

/// Что можно делать с любой сущностью. Где именно лежат данные,
/// остальному коду знать не нужно.
abstract interface class EntityRepository<T extends Entity, Q> {
  Future<PageResult<T>> find(Q query);

  /// все записи без страниц (и удалённые тоже) — нужно для выпадающих
  /// списков и для подсчёта связей
  Future<List<T>> findAll();
  Future<T?> findById(int id);

  /// создаёт запись, id ставит сам репозиторий. если что-то не уникально —
  /// кидает ValidationException
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
