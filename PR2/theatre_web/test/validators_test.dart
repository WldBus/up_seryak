import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_web/core/validators.dart';

// Валидаторы форм (ПР3) — без интерфейса, просто функции.

void main() {
  group('обязательное поле', () {
    test('пустая строка и одни пробелы отклоняются', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
      expect(V.required()(null), isNotNull);
    });

    test('непустая строка принимается, текст ошибки свой', () {
      expect(V.required()('Гамлет'), isNull);
      expect(V.required('Укажите название')(''), 'Укажите название');
    });
  });

  test('длина считается без пробелов по краям', () {
    final v = V.length(min: 2, max: 5);
    expect(v(' а '), isNotNull); // одна буква
    expect(v('драма'), isNull);
    expect(v('трагедия'), isNotNull);
  });

  test('целое и положительное число', () {
    expect(V.integer(min: 1800, max: 2026)('1756'), isNotNull);
    expect(V.integer(min: 1800, max: 2026)('1824'), isNull);
    expect(V.integer()('12.5'), isNotNull);
    expect(V.positive()('0'), isNotNull);
    expect(V.positive(max: 500)('120'), isNull);
  });

  test('почта и телефон', () {
    expect(V.email()('viewer@theatre.local'), isNull);
    expect(V.email()('viewer@'), isNotNull);
    // скобки, пробелы и дефисы в телефоне можно
    expect(V.phone()('+7 (916) 123-45-67'), isNull);
    expect(V.phone()('89161234567'), isNotNull);
  });

  test('имена: только буквы, пробел и дефис', () {
    expect(V.letters()('Анна-Мария Петрова'), isNull);
    expect(V.letters()('Иван2'), isNotNull);
  });

  test('надёжный пароль: длина, цифра, спецсимвол', () {
    final v = V.strongPassword();
    expect(v('Pass1!'), contains('8'));
    expect(v('Password!'), contains('цифра'));
    expect(v('Password1'), contains('спецсимвол'));
    expect(v('Passw0rd!'), isNull);
  });

  test('combine возвращает первую ошибку по порядку', () {
    final v = V.combine([V.required('пусто'), V.length(min: 3)]);
    expect(v(''), 'пусто');
    expect(v('аб'), 'Не короче 3 символов');
    expect(v('абв'), isNull);
  });
}
