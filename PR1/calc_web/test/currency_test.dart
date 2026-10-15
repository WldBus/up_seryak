import 'package:calc_web/logic/calc_result.dart';
import 'package:calc_web/logic/currency.dart';
import 'package:calc_web/logic/numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('перевод в рубли умножает на курс', () {
    final result = convert('USD', 'RUB', '10') as CalcSuccess;
    expect(result.value, 10 * ratesToRub['USD']!);
  });

  test('неизвестная валюта', () {
    final result = convert('USD', 'XXX', '1') as CalcFailure;
    expect(result.message, 'Неизвестная валюта: XXX');
  });

  test('результат округляется', () {
    expect(formatNumber(10 / 3), '3.333333');
    expect(formatNumber(2.50), '2.5');
  });
}
