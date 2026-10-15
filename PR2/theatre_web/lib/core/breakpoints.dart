import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

/// Точки перелома по Material 3: до 600 — телефон, до 1200 — планшет.
ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

/// Ширина, начиная с которой список показывается таблицей, а не карточками.
const tableBreakpoint = 600.0;
