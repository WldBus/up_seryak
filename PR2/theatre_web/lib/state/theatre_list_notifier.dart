import '../models/list_query.dart';
import '../models/theatre.dart';
import '../repositories/actor_repository.dart';
import '../repositories/show_repository.dart';
import '../repositories/theatre_repository.dart';
import 'entity_list_notifier.dart';

class TheatreListNotifier extends EntityListNotifier<Theatre, ListQuery> {
  final ShowRepository _shows;
  final ActorRepository _actors;

  TheatreListNotifier(TheatreRepository repository, this._shows, this._actors)
    : super(repository, ListQuery(sortFields: Theatre.sortFields));

  /// театр — это «один» в связи один ко многим: на него ссылаются спектакли
  /// и актёры. пока они есть, удалить театр нельзя
  @override
  Future<String?> deleteBlockReason(int id) async {
    final shows = (await _shows.findAll()).where((s) => s.theatreId == id);
    final actors = (await _actors.findAll()).where((a) => a.theatreId == id);
    if (shows.isEmpty && actors.isEmpty) return null;
    final theatre = await repository.findById(id);
    return 'Театр «${theatre?.name ?? id}» нельзя удалить: на него ссылаются '
        'спектакли (${shows.length}) и актёры труппы (${actors.length}). '
        'Сначала перенесите их в другой театр или удалите.';
  }
}
