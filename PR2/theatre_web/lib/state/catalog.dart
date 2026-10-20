import 'package:flutter/foundation.dart';

import '../models/actor.dart';
import '../models/entity.dart';
import '../models/genre.dart';
import '../models/theatre.dart';
import '../repositories/actor_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/theatre_repository.dart';

/// Справочники для связей: театры, жанры и актёры. Из них заполняются
/// выпадающие списки и флажки в формах и фильтрах, а в таблицах по ним
/// id превращаются в названия.
///
/// Берутся из репозиториев, а не из констант: добавил жанр — и он сразу
/// появился в форме спектакля.
class Catalog extends ChangeNotifier {
  final TheatreRepository _theatres;
  final GenreRepository _genres;
  final ActorRepository _actors;

  Catalog(this._theatres, this._genres, this._actors);

  List<Theatre> theatres = const [];
  List<Genre> genres = const [];
  List<Actor> actors = const [];
  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> refresh() async {
    final results = await Future.wait([
      _theatres.findAll(),
      _genres.findAll(),
      _actors.findAll(),
    ]);
    theatres = results[0].cast<Theatre>();
    genres = results[1].cast<Genre>();
    actors = results[2].cast<Actor>();
    _loaded = true;
    notifyListeners();
  }

  /// загрузить, если ещё не грузили — для карточек и форм,
  /// которые открыли сразу по ссылке
  Future<void> ensureLoaded() async {
    if (!_loaded) await refresh();
  }

  // в формах можно выбрать только неудалённые записи, а названия
  // показываю и для удалённых — на них могли сослаться раньше
  List<Theatre> get activeTheatres => _active(theatres);
  List<Genre> get activeGenres => _active(genres);
  List<Actor> activeActorsOf(int? theatreId) =>
      _active(actors).where((a) => a.theatreId == theatreId).toList();

  String theatreName(int id) => _byId(theatres, id)?.name ?? '—';
  String genreName(int id) => _byId(genres, id)?.name ?? '—';
  String actorName(int id) => _byId(actors, id)?.fullName ?? '—';

  static List<E> _active<E extends Entity>(List<E> list) =>
      list.where((e) => !e.isDeleted).toList();

  static E? _byId<E extends Entity>(List<E> list, int id) {
    for (final e in list) {
      if (e.id == id) return e;
    }
    return null;
  }
}
