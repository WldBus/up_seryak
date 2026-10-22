import 'package:flutter/foundation.dart';

/// Учебный режим запросов. По ТЗ нужно показать индикатор загрузки
/// (?__delay=1500) и экран ошибки (?__fail=500). Переключается кнопкой
/// в шапке, а интерсептор Dio дописывает параметр к каждому запросу.
enum ApiMode {
  normal('Обычный режим'),
  slow('Задержка 1,5 с (?__delay=1500)'),
  fail('Ошибка сервера (?__fail=500)');

  final String label;

  const ApiMode(this.label);
}

class ApiTestMode extends ChangeNotifier {
  ApiMode _mode = ApiMode.normal;

  ApiMode get mode => _mode;

  set mode(ApiMode value) {
    _mode = value;
    notifyListeners();
  }

  /// что дописать к запросу
  Map<String, String> get queryParameters => switch (_mode) {
    ApiMode.normal => const {},
    ApiMode.slow => const {'__delay': '1500'},
    ApiMode.fail => const {'__fail': '500'},
  };
}
