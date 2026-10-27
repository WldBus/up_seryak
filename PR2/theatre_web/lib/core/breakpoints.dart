import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

/// По ширине окна определяю тип экрана: до 600 — телефон, до 1200 — планшет.
ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

/// Уже 600 px — карточки в одну колонку.
const cardsBreakpoint = 600.0;

/// От 600 до 900 px таблице ещё тесно — карточки в две колонки,
/// с 900 px — таблица (ПР6: 768 — сетка, 1280 — таблица).
const tableBreakpoint = 900.0;

/// Шире этого содержимое не растягиваю: на мониторе 1920 строка таблицы
/// иначе читается через весь экран.
const maxContentWidth = 1400.0;
