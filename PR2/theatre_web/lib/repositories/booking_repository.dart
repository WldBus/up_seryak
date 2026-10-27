import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/booking.dart';
import '../models/page_result.dart';

/// Бронирование билетов — аналог выдачи книги в учебном API.
/// Если свободных мест меньше, чем просят, сервер отвечает 409,
/// и сюда приходит ConflictException с понятным текстом.
abstract interface class BookingRepository {
  Future<void> book({
    required int showId,
    required int spectatorId,
    required int seats,
  });

  /// брони: кассир получает все, зритель — только свои (решает сервер)
  Future<PageResult<Booking>> find({
    String? status,
    String search = '',
    int page = 1,
    int size = 25,
  });

  /// продлить свою бронь (зритель)
  Future<Booking> extend(int id);

  /// закрыть бронь (кассир): выкуплена или отменена
  Future<Booking> close(int id, {required bool paid});
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

  @override
  Future<PageResult<Booking>> find({
    String? status,
    String search = '',
    int page = 1,
    int size = 25,
  }) => guard(() async {
    final response = await _dio.get(
      '/bookings',
      queryParameters: {
        'status': ?status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'sort': 'expiresAt,asc',
        'page': page,
        'size': size,
      },
    );
    final json = response.data as Map<String, dynamic>;
    return PageResult(
      items: [
        for (final e
            in (json['items'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          Booking.fromJson(e),
      ],
      page: json['page'] is int ? json['page'] as int : page,
      size: json['size'] is int ? json['size'] as int : size,
      total: json['total'] is int ? json['total'] as int : 0,
    );
  });

  @override
  Future<Booking> extend(int id) => guard(() async {
    final response = await _dio.post('/bookings/$id/extend');
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Booking> close(int id, {required bool paid}) => guard(() async {
    final response = await _dio.post(
      '/bookings/$id/close',
      data: {'result': paid ? 'paid' : 'cancelled'},
    );
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });
}
