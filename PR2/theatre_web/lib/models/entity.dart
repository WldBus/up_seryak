/// Общее для всех сущностей каталога: идентификатор и отметка
/// логического удаления.
abstract interface class Entity {
  int get id;
  DateTime? get deletedAt;
}

extension EntityDeleted on Entity {
  bool get isDeleted => deletedAt != null;
}
