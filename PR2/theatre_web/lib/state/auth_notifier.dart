import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';

/// Сессия: кто вошёл, его токены и сроки.
///
/// В localStorage (через shared_preferences) лежат токены, время входа,
/// время последнего действия и копия профиля. Пароля там нет никогда.
/// Профиль с ролью хранится только чтобы сразу нарисовать интерфейс после
/// перезагрузки страницы. Его можно поправить в DevTools — тогда появятся
/// чужие кнопки, но сервер всё равно ответит 403: он берёт роль из
/// подписанного токена. А при ближайшем обновлении токена сервер пришлёт
/// настоящий профиль, и подменённая роль пропадёт.
class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';
  static const _kExpires = 'auth_expires_at';
  static const _kLoginAt = 'auth_login_at';
  static const _kActivity = 'auth_last_activity';

  final SharedPreferences _prefs;
  final AuthApi _api;
  final Duration sessionLimit;
  final Duration inactivityTimeout;

  /// текущее время. в тестах подменяется
  final DateTime Function() _now;

  AuthNotifier(
    this._prefs,
    this._api, {
    required this.sessionLimit,
    required this.inactivityTimeout,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _loginAt;
  String? _message;
  Timer? _sessionTimer;
  DateTime? _lastTouchSaved;

  /// идущее обновление токена: если сразу несколько запросов получили 401,
  /// обновление уходит одно, а остальные ждут его результата
  Future<bool>? _refreshing;

  AppUser? get user => _user;
  Role? get role => _user?.role;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  /// когда закончится сессия (общий предел)
  DateTime? get sessionEndsAt => _loginAt?.add(sessionLimit);

  /// почему вышли из системы — показывается на экране входа
  String? get message => _message;

  /// проверка права из core/permissions.dart для текущей роли
  bool can(bool Function(Role? role) check) => check(role);

  /// Восстановление сессии при запуске, до построения интерфейса.
  Future<void> restore() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) return;
    _refreshToken = refresh;
    _accessToken = _prefs.getString(_kAccess);
    _loginAt = _readTime(_kLoginAt);

    // общий предел и неактивность действуют и через перезагрузку страницы
    final loginAt = _loginAt;
    if (loginAt == null || !_now().isBefore(loginAt.add(sessionLimit))) {
      return logout(message: 'Время сессии истекло. Войдите снова.');
    }
    final activity = _readTime(_kActivity);
    if (activity != null && !_now().isBefore(activity.add(inactivityTimeout))) {
      return logout(message: 'Сессия завершена из-за неактивности.');
    }

    final cached = _readUser();
    final expires = _readTime(_kExpires);
    if (_accessToken != null &&
        cached != null &&
        expires != null &&
        _now().isBefore(expires)) {
      // токен доступа ещё жив — рисую интерфейс по сохранённому профилю
      _user = cached;
    } else if (!await refreshTokens()) {
      // сервер недоступен — сессию не сбрасываю, покажу то, что было
      if (_refreshToken == null) return;
      _user = cached;
      if (_user == null) return;
    }
    _startSessionTimer();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    _loginAt = _now();
    await _prefs.setInt(_kLoginAt, _loginAt!.millisecondsSinceEpoch);
    await _save(result);
    _message = null;
    touch(force: true);
    _startSessionTimer();
    notifyListeners();
  }

  /// регистрация и сразу вход под новой учётной записью
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    await _api.register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
    );
    await login(username, password);
  }

  /// Обновить токен доступа по токену обновления. true — получилось.
  /// Если сервер отказал (401) — выход из системы, повторов нет.
  Future<bool> refreshTokens() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final token = _refreshToken;
    if (token == null) return false;
    try {
      final result = await _api.refresh(token);
      await _save(result);
      notifyListeners();
      return true;
    } on UnauthorizedException {
      await logout(
        message: 'Сессия истекла, обновить её не удалось. Войдите снова.',
        callServer: false,
      );
      return false;
    } on ApiException {
      return false; // сеть или сервер — сессию не трогаю
    }
  }

  Future<void> logout({String? message, bool callServer = true}) async {
    final token = _refreshToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _loginAt = null;
    _sessionTimer?.cancel();
    _message = message;
    for (final key in [
      _kAccess,
      _kRefresh,
      _kUser,
      _kExpires,
      _kLoginAt,
      _kActivity,
    ]) {
      await _prefs.remove(key);
    }
    notifyListeners();
    // токен обновления на сервере тоже аннулирую. если не вышло — не страшно
    if (callServer && token != null) {
      try {
        await _api.logout(token);
      } catch (_) {}
    }
  }

  /// убрать сообщение с экрана входа
  void clearMessage() {
    if (_message == null) return;
    _message = null;
    notifyListeners();
  }

  /// запомнить время последнего действия, чтобы неактивность считалась
  /// и через перезагрузку. пишу не чаще раза в 5 секунд
  void touch({bool force = false}) {
    final now = _now();
    final last = _lastTouchSaved;
    if (!force && last != null && now.difference(last).inSeconds < 5) return;
    _lastTouchSaved = now;
    _prefs.setInt(_kActivity, now.millisecondsSinceEpoch);
  }

  Future<void> _save(AuthResult r) async {
    _accessToken = r.accessToken;
    _refreshToken = r.refreshToken;
    _user = r.user;
    final expires = _now().add(Duration(seconds: r.expiresIn));
    await _prefs.setString(_kAccess, r.accessToken);
    await _prefs.setString(_kRefresh, r.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(r.user.toJson()));
    await _prefs.setInt(_kExpires, expires.millisecondsSinceEpoch);
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    final ends = sessionEndsAt;
    if (ends == null) return;
    _sessionTimer = Timer(ends.difference(_now()), () {
      logout(
        message:
            'Время сессии истекло (${sessionLimit.inMinutes} мин). Войдите снова.',
      );
    });
  }

  AppUser? _readUser() {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  DateTime? _readTime(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
