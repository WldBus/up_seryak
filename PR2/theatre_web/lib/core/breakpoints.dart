import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

/// По ширине окна определяю тип экрана: до 600 — телефон, до 1200 — планшет.
ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

/// Уже 600 px показываю карточки, шире — таблицу.
const tableBreakpoint = 600.0;
