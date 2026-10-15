import '../models/theatre.dart';
import '../models/theatre_query.dart';
import 'entity_repository.dart';

abstract interface class TheatreRepository
    implements EntityRepository<Theatre, TheatreQuery> {
  /// Все театры без страниц — для выпадающего списка фильтра
  /// и подписи театра у спектакля.
  Future<List<Theatre>> findAll();
}
