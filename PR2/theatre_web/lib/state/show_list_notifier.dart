import '../models/show.dart';
import '../models/show_query.dart';
import '../repositories/show_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class ShowListNotifier extends EntityListNotifier<Show, ShowQuery> {
  /// справочники: названия театров, жанров и актёров для таблицы
  /// и варианты для фильтров
  final Catalog catalog;

  ShowListNotifier(ShowRepository shows, this.catalog)
    : super(shows, const ShowQuery());

  @override
  Future<void> beforeLoad() => catalog.refresh();

  /// карточку могут открыть сразу по ссылке, когда список ещё не грузился,
  /// поэтому справочники догружаю и тут
  @override
  Future<Show?> findById(int id) async {
    await catalog.ensureLoaded();
    return super.findById(id);
  }
}
