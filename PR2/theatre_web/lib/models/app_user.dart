import 'json.dart';

/// Роли пользователей. Они не вложены друг в друга: у каждой свой набор
/// действий (что кому можно — в core/permissions.dart).
enum Role {
  viewer('viewer', 'Зритель'),
  cashier('cashier', 'Кассир'),
  admin('admin', 'Администратор');

  final String code;
  final String label;

  const Role(this.code, this.label);

  /// незнакомая роль считается самой безобидной — зрителем. наоборот нельзя:
  /// опечатка не должна выдавать права администратора
  static Role fromCode(String? code) =>
      values.firstWhere((r) => r.code == code, orElse: () => viewer);
}

/// Пользователь, который вошёл в систему. Приходит с сервера при входе
/// и при каждом обновлении токена.
class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;

  /// карточка зрителя, к которой привязан пользователь (у зрителя — его брони)
  final int? spectatorId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.spectatorId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.code,
    'spectatorId': spectatorId,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: readInt(json, 'id'),
    username: readString(json, 'username'),
    fullName: readString(json, 'fullName'),
    email: readString(json, 'email'),
    role: Role.fromCode(json['role'] as String?),
    spectatorId: json['spectatorId'] is int ? json['spectatorId'] as int : null,
  );
}
