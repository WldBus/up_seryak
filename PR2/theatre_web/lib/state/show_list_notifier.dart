import '../models/show.dart';
import '../models/show_query.dart';
import '../models/theatre.dart';
import '../repositories/show_repository.dart';
import '../repositories/theatre_repository.dart';
import 'entity_list_notifier.dart';

class ShowListNotifier extends EntityListNotifier<Show, ShowQuery> {
  final TheatreRepository _theatres;

  ShowListNotifier(ShowRepository shows, this._theatres)
    : super(shows, const ShowQuery());

  /// Справочник театров: для фильтра и подписи в строке спектакля.
  List<Theatre> theatres = const [];

  String theatreName(int id) {
    for (final t in theatres) {
      if (t.id == id) return t.name;
    }
    return '—';
  }

  @override
  Future<void> beforeLoad() async {
    theatres = await _theatres.findAll();
  }

  /// Карточку могут открыть по прямой ссылке, когда список ещё не
  /// загружался, поэтому справочник театров подгружается и здесь.
  @override
  Future<Show?> findById(int id) async {
    if (theatres.isEmpty) theatres = await _theatres.findAll();
    return super.findById(id);
  }
}
