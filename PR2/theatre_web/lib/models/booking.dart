import 'json.dart';

/// Состояние брони. Бронь держится несколько дней, потом сгорает.
enum BookingStatus {
  active('active', 'Действует'),
  paid('paid', 'Выкуплена'),
  cancelled('cancelled', 'Отменена'),
  expired('expired', 'Сгорела');

  final String code;
  final String label;

  const BookingStatus(this.code, this.label);

  static BookingStatus fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => expired);
}

/// Бронирование билетов — аналог выдачи книги в учебном API.
class Booking {
  final int id;
  final int spectatorId;
  final String spectatorName;
  final int showId;
  final String showTitle;
  final DateTime? showDate;
  final int price;
  final int seats;
  final BookingStatus status;
  final DateTime? expiresAt;

  /// продлевали ли уже (продлить можно один раз)
  final bool extended;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.spectatorId,
    required this.spectatorName,
    required this.showId,
    required this.showTitle,
    required this.showDate,
    required this.price,
    required this.seats,
    required this.status,
    required this.expiresAt,
    required this.extended,
    required this.createdAt,
  });

  bool get isActive => status == BookingStatus.active;

  int get total => price * seats;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final spectator = readMap(json, 'spectator');
    final show = readMap(json, 'show');
    return Booking(
      id: readInt(json, 'id'),
      spectatorId: readInt(spectator, 'id'),
      spectatorName: readString(spectator, 'fullName'),
      showId: readInt(show, 'id'),
      showTitle: readString(show, 'title'),
      showDate: readDate(show, 'date'),
      price: readInt(show, 'price'),
      seats: readInt(json, 'seats'),
      status: BookingStatus.fromCode(json['status'] as String?),
      expiresAt: readDate(json, 'expiresAt')?.toLocal(),
      extended: json['extended'] == true,
      createdAt: readDate(json, 'createdAt')?.toLocal(),
    );
  }
}
