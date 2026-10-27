import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/admin_repository.dart';

/// Состояние раздела администратора: пользователи и статистика.
class AdminNotifier extends ChangeNotifier {
  final AdminRepository _repo;

  AdminNotifier(this._repo);

  List<AppUser>? _users;
  TheatreStats? _stats;
  String? _error;
  bool _loading = false;
  bool _disposed = false;

  List<AppUser>? get users => _users;
  TheatreStats? get stats => _stats;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> loadUsers({String search = ''}) =>
      _run(() async => _users = await _repo.users(search: search));

  Future<void> loadStats() => _run(() async => _stats = await _repo.stats());

  /// сменить роль. свою сервер менять не даст (409), ошибка уйдёт наружу
  Future<void> setRole(AppUser user, Role role) async {
    final updated = await _repo.setRole(user.id, role);
    _users = [
      for (final u in _users ?? const <AppUser>[])
        if (u.id == updated.id) updated else u,
    ];
    _notify();
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    _notify();
    try {
      await action();
    } catch (e) {
      _error = '$e';
    }
    _loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
