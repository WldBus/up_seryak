import 'entity.dart';
import 'json.dart';

/// Актёр. Связан со спектаклями (многие ко многим) и с театром, где он
/// в труппе, — по труппе фильтруются актёры в форме спектакля.
class Actor implements Entity {
  /// по каким полям можно сортировать, первое — по умолчанию
  static const sortFields = ['lastName', 'country', 'birthYear'];

  @override
  final int id;
  final String lastName;
  final String firstName;
  final String country;
  final int birthYear;
  final int theatreId;
  @override
  final DateTime? deletedAt;

  const Actor({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.country,
    required this.birthYear,
    required this.theatreId,
    this.deletedAt,
  });

  String get fullName => '$lastName $firstName';

  Actor copyWith({
    int? id,
    String? lastName,
    String? firstName,
    String? country,
    int? birthYear,
    int? theatreId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Actor(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      theatreId: theatreId ?? this.theatreId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'country': country,
    'birthYear': birthYear,
    'theatreId': theatreId,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Actor.fromJson(Map<String, dynamic> json) => Actor(
    id: readInt(json, 'id'),
    lastName: readString(json, 'lastName'),
    firstName: readString(json, 'firstName'),
    country: readString(json, 'country'),
    birthYear: readInt(json, 'birthYear'),
    theatreId: readInt(json, 'theatreId'),
    deletedAt: readDate(json, 'deletedAt'),
  );
}
