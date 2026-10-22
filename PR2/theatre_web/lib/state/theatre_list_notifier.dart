import '../models/list_query.dart';
import '../models/theatre.dart';
import '../repositories/theatre_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class TheatreListNotifier extends EntityListNotifier<Theatre, ListQuery> {
  final Catalog catalog;

  TheatreListNotifier(TheatreRepository repository, this.catalog)
    : super(repository, ListQuery(sortFields: Theatre.sortFields));

  // удалить театр, на который ссылаются спектакли и актёры, не даст
  // сервер (409). а после любых изменений список театров в формах устарел
  @override
  void afterChange() => catalog.invalidate();
}
