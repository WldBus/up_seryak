import 'entity.dart';

class Theatre implements Entity {
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
}
