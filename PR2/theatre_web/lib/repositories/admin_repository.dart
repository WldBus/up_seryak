import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';

/// Статистика для администратора — то, что отдаёт GET /api/stats.
class TheatreStats {
  final int shows;
  final int theatres;
  final int actors;
  final int spectators;
  final Map<String, int> users;
  final Map<String, int> bookings;
  final int seatsSold;
  final int revenue;

  /// самые продаваемые спектакли: название, продано мест, всего мест
  final List<(String, int, int)> topShows;

  const TheatreStats({
    required this.shows,
    required this.theatres,
    required this.actors,
    required this.spectators,
    required this.users,
    required this.bookings,
    required this.seatsSold,
    required this.revenue,
    required this.topShows,
  });

  factory TheatreStats.fromJson(Map<String, dynamic> j) {
    int n(Object? v) => v is int ? v : 0;
    Map<String, int> m(Object? v) => v is Map
        ? v.map((k, x) => MapEntry('$k', n(x)))
        : const <String, int>{};
    return TheatreStats(
      shows: n(j['shows']),
      theatres: n(j['theatres']),
      actors: n(j['actors']),
      spectators: n(j['spectators']),
      users: m(j['users']),
      bookings: m(j['bookings']),
      seatsSold: n(j['seatsSold']),
      revenue: n(j['revenue']),
      topShows: [
        for (final s in (j['topShows'] as List? ?? const []).whereType<Map>())
          ('${s['title'] ?? ''}', n(s['sold']), n(s['seatsTotal'])),
      ],
    );
  }
}

/// Запросы администратора: пользователи, роли, статистика.
abstract interface class AdminRepository {
  Future<List<AppUser>> users({String search = ''});

  Future<AppUser> setRole(int userId, Role role);

  Future<TheatreStats> stats();
}

class ApiAdminRepository implements AdminRepository {
  final Dio _dio;

  ApiAdminRepository(this._dio);

  @override
  Future<List<AppUser>> users({String search = ''}) => guard(() async {
    final response = await _dio.get(
      '/users',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'size': 100,
      },
    );
    final items = (response.data as Map<String, dynamic>)['items'];
    return [
      if (items is List)
        for (final e in items.whereType<Map<String, dynamic>>())
          AppUser.fromJson(e),
    ];
  });

  @override
  Future<AppUser> setRole(int userId, Role role) => guard(() async {
    final response = await _dio.patch(
      '/users/$userId',
      data: {'role': role.code},
    );
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<TheatreStats> stats() => guard(() async {
    final response = await _dio.get('/stats');
    return TheatreStats.fromJson(response.data as Map<String, dynamic>);
  });
}
