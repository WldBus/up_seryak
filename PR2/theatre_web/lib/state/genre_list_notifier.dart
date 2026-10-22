import '../models/genre.dart';
import '../models/list_query.dart';
import '../repositories/genre_repository.dart';
import 'catalog.dart';
import 'entity_list_notifier.dart';

class GenreListNotifier extends EntityListNotifier<Genre, ListQuery> {
  final Catalog catalog;

  GenreListNotifier(GenreRepository repository, this.catalog)
    : super(repository, ListQuery(sortFields: Genre.sortFields));

  /// жанры поменялись — флажки в форме спектакля надо обновить
  @override
  void afterChange() => catalog.invalidate();
}
