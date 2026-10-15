import 'package:calc_web/logic/calc_result.dart';
import 'package:calc_web/logic/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('сложение и вычитание', () {
    expect((calculate('2', '+', '3') as CalcSuccess).value, 5);
    expect((calculate('2', '-', '5') as CalcSuccess).value, -3);
  });

  test('умножение и деление', () {
    expect((calculate('1.5', '*', '4') as CalcSuccess).value, 6);
    expect((calculate('10', '/', '4') as CalcSuccess).value, 2.5);
  });

  test('запятая принимается как десятичный разделитель', () {
    expect((calculate('2,5', '+', '0,5') as CalcSuccess).value, 3);
  });

  test('плюс, ставший пробелом после перезагрузки, считается сложением', () {
    expect((calculate('10', ' ', '3') as CalcSuccess).value, 13);
  });

  test('деление на ноль', () {
    final result = calculate('5', '/', '0') as CalcFailure;
    expect(result.message, 'Деление на ноль невозможно');
  });

  test('нечисловое значение', () {
    final result = calculate('abc', '+', '1') as CalcFailure;
    expect(result.message, 'В адресе переданы не числа');
  });

  test('неизвестная операция', () {
    final result = calculate('1', '%', '2') as CalcFailure;
    expect(result.message, 'Неизвестная операция');
  });

  test('отсутствует обязательный параметр', () {
    final result = calculate(null, '+', '2') as CalcFailure;
    expect(result.message, 'В адресе не хватает параметров: a');
  });
}
