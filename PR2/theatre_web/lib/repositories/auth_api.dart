import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';

/// Что сервер отдаёт при входе и при обновлении токена.
class AuthResult {
  final String accessToken;
  final String refreshToken;

  /// сколько секунд живёт токен доступа
  final int expiresIn;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    expiresIn: json['expiresIn'] is int ? json['expiresIn'] as int : 900,
    user: AppUser.fromJson(
      json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : const {},
    ),
  );
}

/// Запросы /api/auth/*. У них свой Dio без обновления токена: иначе
/// неверный пароль (401) запустил бы обновление, оно тоже 401 — и по кругу.
abstract interface class AuthApi {
  Future<AuthResult> login(String username, String password);

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  });

  Future<AuthResult> refresh(String refreshToken);

  Future<void> logout(String refreshToken);
}

class DioAuthApi implements AuthApi {
  final Dio _dio;

  DioAuthApi(this._dio);

  @override
  Future<AuthResult> login(String username, String password) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) => guard(
    () => _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
      },
    ),
  );

  @override
  Future<AuthResult> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> logout(String refreshToken) => guard(
    () => _dio.post('/auth/logout', data: {'refreshToken': refreshToken}),
  );
}
