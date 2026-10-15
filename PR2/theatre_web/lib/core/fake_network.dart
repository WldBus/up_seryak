import 'package:flutter/foundation.dart';

/// Имитация сети для репозиториев в памяти: небольшая задержка, чтобы был
/// виден индикатор загрузки, и переключатель «сеть недоступна», чтобы
/// можно было проверить состояние ошибки.
class FakeNetwork extends ChangeNotifier {
  bool _offline = false;

  bool get offline => _offline;

  void toggleOffline() {
    _offline = !_offline;
    notifyListeners();
  }

  Future<void> roundTrip() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (_offline) {
      throw const NetworkException('сервер недоступен');
    }
  }
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => message;
}
