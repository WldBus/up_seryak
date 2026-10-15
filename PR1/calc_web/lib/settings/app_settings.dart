import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/currency.dart';

/// Настройки, которые должны пережить перезагрузку страницы.
/// На web shared_preferences хранит их в localStorage браузера.
class AppSettings extends ChangeNotifier {
  static const _darkKey = 'dark_theme';
  static const _fromKey = 'converter_from';
  static const _toKey = 'converter_to';

  SharedPreferences? _prefs;
  bool _isDark = false;
  String _lastFrom = 'USD';
  String _lastTo = 'RUB';

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  String get lastFrom => _lastFrom;
  String get lastTo => _lastTo;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _isDark = prefs.getBool(_darkKey) ?? false;

    // localStorage может поправить сам пользователь, поэтому значения проверяются
    final from = prefs.getString(_fromKey);
    final to = prefs.getString(_toKey);
    if (ratesToRub.containsKey(from)) _lastFrom = from!;
    if (ratesToRub.containsKey(to)) _lastTo = to!;
  }

  void toggleTheme() {
    _isDark = !_isDark;
    _prefs?.setBool(_darkKey, _isDark);
    notifyListeners();
  }

  void saveCurrencyPair(String from, String to) {
    _lastFrom = from;
    _lastTo = to;
    _prefs?.setString(_fromKey, from);
    _prefs?.setString(_toKey, to);
  }
}

final appSettings = AppSettings();
