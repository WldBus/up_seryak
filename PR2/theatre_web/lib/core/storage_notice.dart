import 'package:flutter/foundation.dart';

/// Сообщение сверху экрана, если с сохранёнными данными что-то не так:
/// формат устарел или данные побились, и загрузился начальный набор.
class StorageNotice extends ChangeNotifier {
  final List<String> _messages = [];

  List<String> get messages => List.unmodifiable(_messages);

  void add(String message) {
    _messages.add(message);
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
