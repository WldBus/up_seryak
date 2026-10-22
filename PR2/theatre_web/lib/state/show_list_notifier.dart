import '../models/show.dart';
import '../models/show_query.dart';
import '../models/spectator.dart';
import '../repositories/booking_repository.dart';
import '../repositories/show_repository.dart';
import '../repositories/spectator_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class ShowListNotifier extends EntityListNotifier<Show, ShowQuery> {
  /// справочники: названия театров, жанров и актёров для таблицы
  /// и варианты для фильтров
  final Catalog catalog;
  final SpectatorRepository _spectators;
  final BookingRepository _bookings;

  ShowListNotifier(
    ShowRepository shows,
    this.catalog,
    this._spectators,
    this._bookings,
  ) : super(shows, const ShowQuery());

  /// справочники берутся из кэша, заново с сервера не грузятся
  @override
  Future<void> beforeLoad() => catalog.ensureLoaded();

  /// карточку могут открыть сразу по ссылке, когда список ещё не грузился,
  /// поэтому справочники догружаю и тут
  @override
  Future<Show?> findById(int id) async {
    await catalog.ensureLoaded();
    return super.findById(id);
  }

  /// зрители для окна бронирования (только неудалённые)
  Future<List<Spectator>> spectatorsForBooking() async =>
      (await _spectators.findAll()).where((s) => s.deletedAt == null).toList();

  /// бронирование билетов. если мест не хватает, сервер ответит 409,
  /// и наружу уйдёт ConflictException с понятным текстом
  Future<void> book(int showId, int spectatorId, int seats) async {
    await _bookings.book(
      showId: showId,
      spectatorId: spectatorId,
      seats: seats,
    );
    // свободных мест стало меньше — обновлю список, если он уже открывался
    await reloadIfStarted();
  }
}
