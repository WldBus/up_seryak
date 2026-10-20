import 'entity.dart';
import 'json.dart';

/// Театр. У одного театра много спектаклей и много актёров в труппе.
class Theatre implements Entity {
  /// по каким полям можно сортировать, первое — по умолчанию
  static const sortFields = ['name', 'city', 'hallSeats', 'founded'];

  @override
  final int id;
  final String name;
  final String city;
  final String address;
  final int hallSeats;
  final int founded;
  @override
  final DateTime? deletedAt;

  const Theatre({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.hallSeats,
    required this.founded,
    this.deletedAt,
  });

  Theatre copyWith({
    int? id,
    String? name,
    String? city,
    String? address,
    int? hallSeats,
    int? founded,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Theatre(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      hallSeats: hallSeats ?? this.hallSeats,
      founded: founded ?? this.founded,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'address': address,
    'hallSeats': hallSeats,
    'founded': founded,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Theatre.fromJson(Map<String, dynamic> json) => Theatre(
    id: readInt(json, 'id'),
    name: readString(json, 'name'),
    city: readString(json, 'city'),
    address: readString(json, 'address'),
    hallSeats: readInt(json, 'hallSeats'),
    founded: readInt(json, 'founded'),
    deletedAt: readDate(json, 'deletedAt'),
  );
}
