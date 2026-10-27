import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Есть ли связь с сервером (ПР6). Dio сообщает сюда, прошёл запрос или
/// упал по сети. Пока связи нет, раз в 5 секунд стучусь в /__health, и как
/// только сервер ответил — экраны с ошибкой сами повторяют загрузку
/// (RetryOnReconnect), перезагружать страницу не нужно.
class ConnectionStatus extends ChangeNotifier {
  final Future<bool> Function() ping;
  final Duration interval;

  ConnectionStatus({
    required this.ping,
    this.interval = const Duration(seconds: 5),
  });

  /// проверка через отдельный Dio: без повторов, токена и журнала
  factory ConnectionStatus.forServer(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
    return ConnectionStatus(
      ping: () async {
        try {
          final r = await dio.get<Object?>('/__health');
          return r.statusCode == 200;
        } on DioException {
          return false;
        }
      },
    );
  }

  bool _online = true;
  bool _checking = false;
  Timer? _timer;

  bool get online => _online;

  void reportSuccess() {
    if (_online) return;
    _online = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reportFailure() {
    if (!_online) return;
    _online = false;
    _timer = Timer.periodic(interval, (_) => check());
    notifyListeners();
  }

  /// кнопка «Проверить сейчас» и таймер
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      if (await ping()) reportSuccess();
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Сбой именно сети (сервер не ответил), а не ошибка в ответе.
bool isNetworkFailure(DioException e) => switch (e.type) {
  DioExceptionType.connectionError ||
  DioExceptionType.connectionTimeout ||
  DioExceptionType.receiveTimeout => true,
  _ => false,
};
