/// Жанры — короткий неизменяемый справочник.
class Genre {
  final int id;
  final String name;

  const Genre(this.id, this.name);
}

const genres = [
  Genre(1, 'Драма'),
  Genre(2, 'Комедия'),
  Genre(3, 'Опера'),
  Genre(4, 'Балет'),
  Genre(5, 'Мюзикл'),
  Genre(6, 'Трагедия'),
  Genre(7, 'Детский'),
];

String genreName(int id) =>
    genres.firstWhere((g) => g.id == id, orElse: () => Genre(id, '?')).name;
