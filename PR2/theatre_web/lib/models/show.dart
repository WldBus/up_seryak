import 'entity.dart';
import 'json.dart';

/// Спектакль — на него бронируют билеты.
///
/// Связи: театр — многие к одному (theatreId), жанры и актёры —
/// многие ко многим (genreIds, actorIds).
class Show implements Entity {
  @override
  final int id;
  final String title;

  /// код постановки, например SP-1004. не должен повторяться, по нему тоже ищем
  final String code;
  final DateTime date;
  final int duration; // минуты
  final int price; // рубли
  final int theatreId;
  final List<int> genreIds;
  final List<int> actorIds;
  final int seatsTotal;
  final int seatsAvailable;
  @override
  final DateTime? deletedAt;

  const Show({
    required this.id,
    required this.title,
    required this.code,
    required this.date,
    required this.duration,
    required this.price,
    required this.theatreId,
    required this.genreIds,
    required this.actorIds,
    required this.seatsTotal,
    required this.seatsAvailable,
    this.deletedAt,
  });

  Show copyWith({
    int? id,
    String? title,
    String? code,
    DateTime? date,
    int? duration,
    int? price,
    int? theatreId,
    List<int>? genreIds,
    List<int>? actorIds,
    int? seatsTotal,
    int? seatsAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Show(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      theatreId: theatreId ?? this.theatreId,
      genreIds: genreIds ?? this.genreIds,
      actorIds: actorIds ?? this.actorIds,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      // без этого флага не понять: «не трогать поле» или «сбросить в null»
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'code': code,
    'date': date.toIso8601String(),
    'duration': duration,
    'price': price,
    'theatreId': theatreId,
    'genreIds': genreIds,
    'actorIds': actorIds,
    'seatsTotal': seatsTotal,
    'seatsAvailable': seatsAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Show.fromJson(Map<String, dynamic> json) => Show(
    id: readInt(json, 'id'),
    title: readString(json, 'title'),
    code: readString(json, 'code'),
    date: readDate(json, 'date') ?? DateTime(2000),
    duration: readInt(json, 'duration'),
    price: readInt(json, 'price'),
    // с сервера приходят развёрнутые theatre, genres, actors
    theatreId: readRefId(json, 'theatreId', 'theatre'),
    genreIds: readRefIds(json, 'genreIds', 'genres'),
    actorIds: readRefIds(json, 'actorIds', 'actors'),
    seatsTotal: readInt(json, 'seatsTotal'),
    seatsAvailable: readInt(json, 'seatsAvailable'),
    deletedAt: readDate(json, 'deletedAt'),
  );
}
