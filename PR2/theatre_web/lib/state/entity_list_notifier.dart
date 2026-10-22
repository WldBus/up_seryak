import 'package:flutter/foundation.dart';

import '../models/entity.dart';
import '../repositories/entity_repository.dart';
import 'list_state.dart';

/// Состояние любого списка: фильтры, загруженная страница и выбранные строки.
/// Виджеты получают данные только через него.
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

  /// экран вызывает это, когда фильтры пришли из адреса. если они не
  /// поменялись (например, вернулись на вкладку) — заново не грузим
  void sync(Q next) {
    if (_started && next == _query) return;
    _started = true;
    applyQuery(next);
  }

  Future<void> applyQuery(Q next) {
    _query = next;
    _selected.clear(); // фильтры поменялись — старое выделение уже не нужно
    return load();
  }

  /// тут можно что-то догрузить перед списком, например справочники
  @protected
  Future<void> beforeLoad() async {}

  /// вызывается после любого изменения данных: сохранение, удаление,
  /// восстановление. театры, жанры и актёры сбрасывают тут кэш справочников
  @protected
  void afterChange() {}

  Future<void> load() async {
    // если пользователь уже поменял фильтры, ответ на старый запрос
    // выкидываем, а то покажутся не те данные
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

  /// перезагрузить список, если его уже открывали (иначе загрузит экран)
  @protected
  Future<void> reloadIfStarted() async {
    if (_started) await load();
  }

  /// сохраняет запись из формы: id == 0 — новая, иначе редактирование.
  /// ValidationException тут не ловлю — форма сама покажет ошибки под полями
  Future<T> save(T item) async {
    final saved = item.id == 0
        ? await repository.create(item)
        : await repository.update(item);
    afterChange();
    if (_started) await load();
    return saved;
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    _notify();
  }

  /// галочка в заголовке таблицы: выбрать или снять всю страницу
  void selectPage(bool select) {
    final state = _state;
    if (state is! ListLoaded<T>) return;
    final ids = state.page.items.where((e) => !e.isDeleted).map((e) => e.id);
    select ? _selected.addAll(ids) : _selected.removeAll(ids);
    _notify();
  }

  // Связи перед удалением с ПР4 проверяет сервер: если на запись ссылаются,
  // он отвечает 409, и сюда приходит ConflictException с текстом и числом
  // связанных записей. bulk-delete при этом не удаляет вообще ничего.

  Future<int> deleteSelected() async {
    final count = await repository.deleteMany(_selected.toList());
    _selected.clear();
    afterChange();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await repository.softDelete(id);
    _selected.remove(id);
    afterChange();
    if (_started) await load();
  }

  Future<void> hardDelete(int id) async {
    await repository.hardDelete(id);
    _selected.remove(id);
    afterChange();
    if (_started) await load();
  }

  Future<void> restore(int id) async {
    await repository.restore(id);
    afterChange();
    if (_started) await load();
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
