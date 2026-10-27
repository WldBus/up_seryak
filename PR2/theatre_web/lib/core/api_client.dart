import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'api_test_mode.dart';
import 'config.dart';

/// Настроенный Dio для всего приложения: адрес, таймауты, общая обработка
/// ошибок, журнал запросов, токен в каждом запросе, обновление токена
/// при 401 и повтор чтения при сбое сети.
Dio buildDio({
  String baseUrl = apiBaseUrl,
  String? Function()? tokenProvider,
  // обновить токен; true — получилось и запрос можно повторить
  Future<bool> Function()? onUnauthorized,
  ApiTestMode? testMode,
  Duration retryDelay = const Duration(milliseconds: 500),
  // журнал пишу только в режиме отладки, в тестах его можно выключить
  bool log = kDebugMode,
}) {
  void write(RequestOptions options, String result) {
    if (log) _log(options, result);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // 4xx не бросают исключение — разбираю их сам в onResponse
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // заголовок ставлю здесь, перед каждым запросом: так в него всегда
        // попадает текущий токен, в том числе только что обновлённый
        final token = tokenProvider?.call();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        final extra = testMode?.queryParameters ?? const {};
        if (extra.isNotEmpty) {
          options.queryParameters = {...options.queryParameters, ...extra};
        }
        options.extra['startedAt'] = DateTime.now();
        return handler.next(options);
      },
      onResponse: (response, handler) {
        write(response.requestOptions, '${response.statusCode}');
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          // throw тут не подходит: Dio завернёт исключение в DioException
          // с типом unknown, и ValidationException потеряется. Поэтому
          // отправляю ответ по ветке ошибок сам, с уже разобранной ошибкой
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // сюда попадают сбои сети, таймауты, 5xx и отклонённые выше 4xx
        // (4xx уже записаны в журнал в onResponse)
        if (error.error is! ApiException) {
          final code = error.response?.statusCode;
          write(error.requestOptions, code != null ? '$code' : error.type.name);
        }
        return handler.next(error);
      },
    ),
  );
  if (onUnauthorized != null) {
    dio.interceptors.add(RefreshInterceptor(dio, onUnauthorized, log: log));
  }
  dio.interceptors.add(RetryInterceptor(dio, baseDelay: retryDelay, log: log));
  return dio;
}

/// Пишет в консоль метод, адрес, код ответа и время.
void _log(RequestOptions options, String result) {
  final started = options.extra['startedAt'];
  final ms = started is DateTime
      ? ' ${DateTime.now().difference(started).inMilliseconds} мс'
      : '';
  debugPrint('[API] ${options.method} ${options.uri} → $result$ms');
}

/// Повтор при сбое сети: не больше трёх раз, пауза растёт (0,5 → 1 → 2 с).
/// Только для GET: повторять создание или удаление нельзя — если первый
/// запрос всё-таки дошёл, получится вторая запись.
class RetryInterceptor extends Interceptor {
  static const maxRetries = 3;

  final Dio dio;
  final Duration baseDelay;
  final bool log;

  RetryInterceptor(this.dio, {required this.baseDelay, this.log = kDebugMode});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retry'] as int?) ?? 0;
    final networkFailure = switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
    final cancelled = options.cancelToken?.isCancelled ?? false;

    if (options.method != 'GET' ||
        !networkFailure ||
        cancelled ||
        attempt >= maxRetries) {
      return handler.next(err);
    }

    await Future.delayed(baseDelay * (1 << attempt));
    if (options.cancelToken?.isCancelled ?? false) return handler.next(err);
    if (log) {
      debugPrint('[API] повтор ${attempt + 1} из $maxRetries: ${options.uri}');
    }
    options.extra['retry'] = attempt + 1;
    try {
      return handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

/// Токен истёк прямо во время работы: сервер ответил 401. Молча обновляю
/// токен и повторяю тот же запрос — пользователь ничего не замечает.
///
/// Чтобы не было бесконечного цикла:
/// * для адресов /auth/ обновления нет: неверный пароль — тоже 401, и без
///   этого условия вход запускал бы обновление, а оно снова 401;
/// * каждый запрос повторяется не больше одного раза (метка в extra);
/// * если обновить не удалось, AuthNotifier выходит из системы, а ошибка
///   уходит дальше как обычная.
class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final Future<bool> Function() refresh;
  final bool log;

  RefreshInterceptor(this.dio, this.refresh, {this.log = kDebugMode});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.path.contains('/auth/') ||
        options.extra['authRetried'] == true) {
      return handler.next(err);
    }
    if (log) debugPrint('[API] 401 — обновляю токен: ${options.uri}');
    if (!await refresh()) return handler.next(err);
    options.extra['authRetried'] = true;
    try {
      // onRequest подставит уже новый токен
      return handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
