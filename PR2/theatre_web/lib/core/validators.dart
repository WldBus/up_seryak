// Все проверки для форм собрал в одном месте, чтобы не копировать их
// в каждую форму. Валидатор возвращает null, если всё ок, или текст
// ошибки — он показывается под полем.

typedef Validator = String? Function(String? value);

class V {
  V._();

  /// поле должно быть заполнено
  static Validator required([String message = 'Поле обязательно']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  /// длина текста от min до max
  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  /// целое число, можно задать min и max
  static Validator integer({int? min, int? max}) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  /// число больше нуля (места, цена и т. п.)
  static Validator positive({int? max}) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return 'Введите целое число';
      if (n <= 0) return 'Значение должно быть больше нуля';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  /// проверка почты
  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) =>
        re.hasMatch(value?.trim() ?? '') ? null : 'Некорректный адрес почты';
  }

  /// российский телефон: +7 и ещё 10 цифр, например +79161234567
  static Validator phone() {
    final re = RegExp(r'^\+7\d{10}$');
    return (value) =>
        re.hasMatch((value ?? '').replaceAll(RegExp(r'[\s()-]'), ''))
        ? null
        : 'Телефон в формате +7 и 10 цифр, например +79161234567';
  }

  /// только буквы, пробел и дефис — для имён и городов
  static Validator letters() {
    final re = RegExp(r'^[A-Za-zА-Яа-яЁё\s-]+$');
    return (value) => re.hasMatch(value?.trim() ?? '')
        ? null
        : 'Только буквы, пробел и дефис';
  }

  /// проверка регуляркой со своим текстом ошибки
  static Validator pattern(RegExp re, String message) {
    return (value) => re.hasMatch(value?.trim() ?? '') ? null : message;
  }

  /// правила пароля при регистрации: текст правила и проверка.
  /// по ним же рисуется список с галочками под полем пароля
  static final passwordRules = <(String, bool Function(String))>[
    ('Не короче 8 символов', (p) => p.length >= 8),
    ('Есть цифра', (p) => RegExp(r'\d').hasMatch(p)),
    (
      'Есть спецсимвол (!, @, #, % и т. п.)',
      (p) => RegExp(r'[^A-Za-zА-Яа-яЁё0-9]').hasMatch(p),
    ),
  ];

  /// надёжный пароль: все правила из passwordRules. сервер проверяет то же
  static Validator strongPassword() {
    return (value) {
      final p = value ?? '';
      for (final (text, ok) in passwordRules) {
        if (!ok(p)) return 'Пароль: ${text.toLowerCase()}';
      }
      return null;
    };
  }

  /// несколько проверок подряд, возвращается первая ошибка
  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
