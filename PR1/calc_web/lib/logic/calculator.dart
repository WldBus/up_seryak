import 'calc_result.dart';
import 'numbers.dart';

/// Операции, которые умеет калькулятор.
const operations = ['+', '-', '*', '/'];

/// Приводит операцию из адреса к одному из знаков [operations].
///
/// Форма кодирует «+» как %2B, но браузер показывает адрес в раскодированном
/// виде, то есть снова с «+». После перезагрузки страницы такой «+» читается
/// как пробел, поэтому одиночный пробел тоже считается сложением.
String? normalizeOperation(String? rawOp) => rawOp == ' ' ? '+' : rawOp;

/// Считает выражение по «сырым» строкам из адреса.
/// Любой из параметров может отсутствовать или быть испорчен.
CalcResult calculate(String? rawA, String? rawOp, String? rawB) {
  final op = normalizeOperation(rawOp);

  final missing = [
    if (rawA == null || rawA.trim().isEmpty) 'a',
    if (op == null || op.isEmpty) 'op',
    if (rawB == null || rawB.trim().isEmpty) 'b',
  ];
  if (missing.isNotEmpty) {
    return CalcFailure('В адресе не хватает параметров: ${missing.join(', ')}');
  }

  final a = parseNumber(rawA);
  final b = parseNumber(rawB);
  if (a == null || b == null) {
    return const CalcFailure('В адресе переданы не числа');
  }

  final double value;
  switch (op) {
    case '+':
      value = a + b;
    case '-':
      value = a - b;
    case '*':
      value = a * b;
    case '/':
      if (b == 0) return const CalcFailure('Деление на ноль невозможно');
      value = a / b;
    default:
      return const CalcFailure('Неизвестная операция');
  }

  if (!value.isFinite) {
    return const CalcFailure('Результат слишком большой');
  }
  return CalcSuccess(value);
}
