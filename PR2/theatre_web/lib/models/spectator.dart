import 'entity.dart';
import 'json.dart';

/// Карта зрителя (один к одному). Отдельно не хранится — лежит прямо
/// внутри зрителя и редактируется в его форме.
class SpectatorCard {
  /// номер карты, 6 цифр, не должен повторяться
  final String number;
  final DateTime issuedAt;

  /// скидка по карте в процентах
  final int discount;

  const SpectatorCard({
    required this.number,
    required this.issuedAt,
    required this.discount,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'discount': discount,
  };

  factory SpectatorCard.fromJson(Map<String, dynamic> json) => SpectatorCard(
    number: readString(json, 'number'),
    issuedAt: readDate(json, 'issuedAt') ?? DateTime(2000),
    discount: readInt(json, 'discount'),
  );
}

/// Зритель, который бронирует билеты.
class Spectator implements Entity {
  /// по каким полям можно сортировать, первое — по умолчанию
  static const sortFields = ['lastName', 'email', 'discount'];

  @override
  final int id;
  final String lastName;
  final String firstName;

  /// почта, тоже не должна повторяться
  final String email;
  final String phone;
  final SpectatorCard card;
  @override
  final DateTime? deletedAt;

  const Spectator({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  String get fullName => '$lastName $firstName';

  Spectator copyWith({
    int? id,
    String? lastName,
    String? firstName,
    String? email,
    String? phone,
    SpectatorCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Spectator(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Spectator.fromJson(Map<String, dynamic> json) => Spectator(
    id: readInt(json, 'id'),
    lastName: readString(json, 'lastName'),
    firstName: readString(json, 'firstName'),
    email: readString(json, 'email'),
    phone: readString(json, 'phone'),
    card: SpectatorCard.fromJson(readMap(json, 'card')),
    deletedAt: readDate(json, 'deletedAt'),
  );
}
