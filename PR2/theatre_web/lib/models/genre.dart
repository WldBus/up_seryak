import 'entity.dart';
import 'json.dart';

/// Жанр, связан со спектаклями многие ко многим.
/// В ПР2 жанры были просто константой, теперь это нормальная сущность.
class Genre implements Entity {
  /// по каким полям можно сортировать, первое — по умолчанию
  static const sortFields = ['name', 'id'];

  @override
  final int id;
  final String name;
  final String description;
  @override
  final DateTime? deletedAt;

  const Genre({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  Genre copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: readInt(json, 'id'),
    name: readString(json, 'name'),
    description: readString(json, 'description'),
    deletedAt: readDate(json, 'deletedAt'),
  );
}
