/// То, что есть у всех сущностей: id, отметка удаления
/// и перевод в JSON для сохранения.
abstract interface class Entity {
  int get id;
  DateTime? get deletedAt;

  Map<String, dynamic> toJson();
}

extension EntityDeleted on Entity {
  bool get isDeleted => deletedAt != null;
}
