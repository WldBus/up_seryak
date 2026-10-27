import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import 'list_state.dart';

/// Брони для «Моих бронирований» (зритель) и «Кассы» (кассир).
/// Запрос один и тот же, а какие брони вернуть, решает сервер по роли
/// в токене: зрителю — только его собственные.
class BookingsNotifier extends ChangeNotifier {
  final BookingRepository _repo;

  BookingsNotifier(this._repo);

  ListState<Booking> _state = const ListLoading();

  /// фильтр по статусу: null — все
  BookingStatus? _status;
  String _search = '';
  int _requestId = 0;
  bool _disposed = false;

  ListState<Booking> get state => _state;
  BookingStatus? get status => _status;
  String get search => _search;

  Future<void> load() async {
    final id = ++_requestId;
    _state = const ListLoading();
    _notify();
    try {
      final page = await _repo.find(
        status: _status?.code,
        search: _search,
        size: 100,
      );
      if (id != _requestId) return;
      _state = ListLoaded(page);
    } catch (e) {
      if (id != _requestId) return;
      _state = ListFailed('Не удалось загрузить бронирования: $e');
    }
    _notify();
  }

  void setStatus(BookingStatus? value) {
    _status = value;
    load();
  }

  void setSearch(String value) {
    _search = value;
    load();
  }

  /// продлить свою бронь. второй раз сервер ответит 409
  Future<void> extend(int id) async {
    await _repo.extend(id);
    await load();
  }

  /// закрыть бронь в кассе: выкуплена или отменена
  Future<void> close(int id, {required bool paid}) async {
    await _repo.close(id, paid: paid);
    await load();
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
