import 'package:dio/dio.dart';

// Свои исключения вместо DioException. Экраны и формы знают только про них,
// а про Dio не знают вообще — так сетевой слой можно поменять, не трогая их.

sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

/// нет соединения, таймаут, сервер выключен или запрос заблокировал CORS
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 401 — не вошли в систему или токен истёк (понадобится в ПР5)
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// 403 — роль не позволяет
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

/// 404
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — на запись ссылаются или не хватает мест
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 422 — ошибки по полям: поле → текст. Форма показывает их под полями
class ValidationException extends ApiException {
  final Map<String, String> errors;

  const ValidationException(super.message, this.errors);
}

/// 5xx и всё непонятное
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

/// ответ с кодом ошибки → наше исключение. текст беру из ответа сервера
ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      (body is Map && body['errors'] is Map)
          ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
          : const {},
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  // 4xx уже разобрал интерсептор и положил в error. если разбирать
  // заново, 422 превратится в ServerException и форма не покажет ошибки
  final existing = e.error;
  if (existing is ApiException) return existing;

  final response = e.response;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    // со стороны Dart ошибка CORS выглядит так же, как выключенный сервер,
    // поэтому подсказка прямо в тексте
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. Если сервер запущен, откройте '
      'консоль браузера (F12) и проверьте, нет ли ошибки CORS.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    // 5xx: текст тоже берём из ответа
    DioExceptionType.badResponse when response != null => mapHttpError(
      response.statusCode ?? 500,
      response.data,
    ),
    _ => const ServerException(),
  };
}

/// Обёртка для каждого запроса: наружу не выпускает DioException,
/// только наши исключения.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}
