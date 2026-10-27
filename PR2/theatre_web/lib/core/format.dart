String _two(int n) => n.toString().padLeft(2, '0');

const _nbsp = ' ';

/// дата в виде 02.11.2026
String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// дата и время: 02.11.2026 19:00
String formatDateTime(DateTime d) =>
    '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';

/// только время: 19:05
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Цена вида 6 500 ₽. Пробел неразрывный, чтобы цена не разъезжалась
/// на две строки.
String formatPrice(int rub) {
  final digits = rub.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(_nbsp);
    buf.write(digits[i]);
  }
  return '$buf$_nbsp₽';
}

/// длительность вида 2 ч 45 мин
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m мин';
  return m == 0 ? '$h ч' : '$h ч $m мин';
}
