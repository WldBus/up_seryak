import '../models/genre.dart';
import '../models/list_query.dart';
import '../repositories/genre_repository.dart';
import '../repositories/show_repository.dart';
import 'entity_list_notifier.dart';

class GenreListNotifier extends EntityListNotifier<Genre, ListQuery> {
  final ShowRepository _shows;

  GenreListNotifier(GenreRepository repository, this._shows)
    : super(repository, ListQuery(sortFields: Genre.sortFields));

  @override
  Future<String?> deleteBlockReason(int id) async {
    final count = (await _shows.findAll())
        .where((s) => s.genreIds.contains(id))
        .length;
    if (count == 0) return null;
    final genre = await repository.findById(id);
    return 'Жанр «${genre?.name ?? id}» нельзя удалить: он указан '
        'у спектаклей ($count).';
  }
}
