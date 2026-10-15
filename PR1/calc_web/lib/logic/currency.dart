import 'calc_result.dart';
import 'numbers.dart';

/// Условные курсы: сколько рублей стоит одна единица валюты.
const Map<String, double> ratesToRub = {
  'RUB': 1.0,
  'USD': 80.0,
  'EUR': 93.5,
  'CNY': 11.2,
  'GBP': 107.0,
  'KZT': 0.155,
  'BYN': 26.5,
};

const Map<String, String> currencyNames = {
  'RUB': 'Российский рубль',
  'USD': 'Доллар США',
  'EUR': 'Евро',
  'CNY': 'Китайский юань',
  'GBP': 'Фунт стерлингов',
  'KZT': 'Казахстанский тенге',
  'BYN': 'Белорусский рубль',
};

/// Переводит сумму из одной валюты в другую через рубль.
/// Параметры приходят из адреса, поэтому могут быть любыми.
CalcResult convert(String? rawFrom, String? rawTo, String? rawAmount) {
  final missing = [
    if (rawFrom == null || rawFrom.trim().isEmpty) 'from',
    if (rawTo == null || rawTo.trim().isEmpty) 'to',
    if (rawAmount == null || rawAmount.trim().isEmpty) 'amount',
  ];
  if (missing.isNotEmpty) {
    return CalcFailure('В адресе не хватает параметров: ${missing.join(', ')}');
  }

  final from = rawFrom!.trim().toUpperCase();
  final to = rawTo!.trim().toUpperCase();
  final fromRate = ratesToRub[from];
  final toRate = ratesToRub[to];
  if (fromRate == null) return CalcFailure('Неизвестная валюта: $from');
  if (toRate == null) return CalcFailure('Неизвестная валюта: $to');

  final amount = parseNumber(rawAmount);
  if (amount == null) return const CalcFailure('Сумма должна быть числом');
  if (amount < 0) return const CalcFailure('Сумма не может быть отрицательной');

  final value = amount * fromRate / toRate;
  if (!value.isFinite) {
    return const CalcFailure('Результат слишком большой');
  }
  return CalcSuccess(value);
}
