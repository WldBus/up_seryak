import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';

/// Бронирование билетов — аналог выдачи книги в учебном API.
/// Если свободных мест меньше, чем просят, сервер отвечает 409,
/// и сюда приходит ConflictException с понятным текстом.
abstract interface class BookingRepository {
  Future<void> book({
    required int showId,
    required int spectatorId,
    required int seats,
  });
}

class ApiBookingRepository implements BookingRepository {
  final Dio _dio;

  ApiBookingRepository(this._dio);

  @override
  Future<void> book({
    required int showId,
    required int spectatorId,
    required int seats,
  }) => guard(
    () => _dio.post(
      '/bookings',
      data: {'showId': showId, 'spectatorId': spectatorId, 'seats': seats},
    ),
  );
}
