import 'entity.dart';

/// Спектакль — показ, на который продаются билеты.
class Show implements Entity {
  @override
  final int id;
  final String title;

  /// Код постановки, например SP-1004. По нему тоже работает поиск.
  final String code;
  final DateTime date;
  final int duration; // минуты
  final int price; // рубли
  final int theatreId;
  final List<int> genreIds;
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
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      // Без флага нельзя отличить «не менять поле» от «сбросить в null»
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
