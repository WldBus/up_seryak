import 'package:flutter/foundation.dart';

import '../models/entity.dart';
import '../repositories/entity_repository.dart';
import 'list_state.dart';

/// Состояние списка любой сущности: условия отбора, загруженная страница
/// и выделенные строки. Виджеты работают с данными только через него.
class EntityListNotifier<T extends Entity, Q> extends ChangeNotifier {
  final EntityRepository<T, Q> repository;

  EntityListNotifier(this.repository, this._query);

  Q _query;
  ListState<T> _state = const ListLoading();
  final Set<int> _selected = {};
  bool _started = false;
  bool _disposed = false;
  int _requestId = 0;

  Q get query => _query;
  ListState<T> get state => _state;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  /// Вызывается экраном, когда условия пришли из адреса. Если они
  /// не изменились (например, вернулись на вкладку), повторно не грузим.
  void sync(Q next) {
    if (_started && next == _query) return;
    _started = true;
    applyQuery(next);
  }

  Future<void> applyQuery(Q next) {
    _query = next;
    _selected.clear(); // при смене условий выделение теряет смысл
    return load();
  }

  /// Дополнительная загрузка перед выборкой, например справочников.
  @protected
  Future<void> beforeLoad() async {}

  Future<void> load() async {
    // Ответ на устаревший запрос (пользователь уже сменил условия)
    // отбрасывается, иначе на экране окажутся не те данные
    final id = ++_requestId;
    _state = const ListLoading();
    _notify();

    try {
      await beforeLoad();
      final page = await repository.find(_query);
      if (id != _requestId) return;
      _state = ListLoaded(page);
    } catch (e) {
      if (id != _requestId) return;
      _state = ListFailed('Не удалось загрузить список: $e');
    }
    _notify();
  }

  Future<T?> findById(int id) => repository.findById(id);

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    _notify();
  }

  /// Флажок в заголовке таблицы: выделить или снять всю текущую страницу.
  void selectPage(bool select) {
    final state = _state;
    if (state is! ListLoaded<T>) return;
    final ids = state.page.items.where((e) => !e.isDeleted).map((e) => e.id);
    select ? _selected.addAll(ids) : _selected.removeAll(ids);
    _notify();
  }

  Future<int> deleteSelected() async {
    final count = await repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await repository.restore(id);
    await load();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
