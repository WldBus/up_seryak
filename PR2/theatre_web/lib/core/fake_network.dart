import 'package:flutter/foundation.dart';

/// Как бы «сеть» для данных в памяти. Делает задержку, чтобы было видно
/// загрузку, и умеет «падать» по кнопке — так проверяю экран ошибки.
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
