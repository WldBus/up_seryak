/// Разбирает число из строки. Принимает и точку, и запятую.
/// Возвращает null, если строка не является обычным конечным числом.
double? parseNumber(String? raw) {
  if (raw == null) return null;
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  // double.tryParse понимает 'NaN' и 'Infinity', но для расчётов они не годятся
  if (value == null || !value.isFinite) return null;
  return value;
}

/// Готовит введённое число к передаче через адрес: запятая заменяется точкой,
/// а знак «+» убирается, потому что в строке запроса он означает пробел.
String numberForUrl(String input) {
  return input.trim().replaceAll(',', '.').replaceAll('+', '');
}

/// Округляет число до [digits] знаков после запятой и убирает лишние нули:
/// 3.3333333333333335 -> 3.333333, 2.50 -> 2.5, 4.0 -> 4.
String formatNumber(double value, {int digits = 6}) {
  var text = value.toStringAsFixed(digits);
  // Очень большие числа Dart выводит в виде 1e+21, их не трогаем
  if (text.contains('e') || !text.contains('.')) return text;

  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text == '-0' ? '0' : text;
}
