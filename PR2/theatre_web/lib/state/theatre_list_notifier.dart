import '../models/theatre.dart';
import '../models/theatre_query.dart';
import '../repositories/theatre_repository.dart';
import 'entity_list_notifier.dart';

class TheatreListNotifier extends EntityListNotifier<Theatre, TheatreQuery> {
  TheatreListNotifier(TheatreRepository repository)
    : super(repository, const TheatreQuery());
}
