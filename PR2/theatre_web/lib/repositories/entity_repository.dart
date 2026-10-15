import '../models/entity.dart';
import '../models/page_result.dart';

/// Что приложение умеет делать с любой сущностью каталога,
/// безотносительно того, где лежат данные.
abstract interface class EntityRepository<T extends Entity, Q> {
  Future<PageResult<T>> find(Q query);
  Future<T?> findById(int id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
