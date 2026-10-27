import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_web/models/app_user.dart';
import 'package:theatre_web/models/booking.dart';
import 'package:theatre_web/models/genre.dart';
import 'package:theatre_web/models/list_query.dart';
import 'package:theatre_web/models/show.dart';

// Разбор ответов сервера: поле может не прийти, быть null или другого типа.

void main() {
  test('отсутствующие поля спектакля не приводят к исключению', () {
    final show = Show.fromJson({'id': 1});
    expect(show.title, '');
    expect(show.genreIds, isEmpty);
    expect(show.actorIds, isEmpty);
    expect(show.price, 0);
  });

  test('связи спектакля читаются и из id, и из развёрнутых объектов', () {
    final show = Show.fromJson({
      'id': 7,
      'title': 'Гамлет',
      'price': '1500', // число строкой — тоже понимаю
      'date': '2026-11-20T19:00:00',
      'theatre': {'id': 2, 'name': 'МХТ'},
      'genres': [
        {'id': 1},
        {'id': 4},
      ],
      'actorIds': [3, 5],
    });
    expect(show.price, 1500);
    expect(show.theatreId, 2);
    expect(show.genreIds, [1, 4]);
    expect(show.actorIds, [3, 5]);
    expect(show.date, DateTime(2026, 11, 20, 19));
  });

  test('жанр: toJson и fromJson дают ту же запись', () {
    const genre = Genre(id: 4, name: 'Комедия', description: 'смешно');
    final copy = Genre.fromJson(genre.toJson());
    expect(copy.id, 4);
    expect(copy.name, 'Комедия');
    expect(copy.description, 'смешно');
    expect(copy.deletedAt, isNull);
  });

  test('незнакомая роль и незнакомый статус — самые безобидные', () {
    final user = AppUser.fromJson({'id': 1, 'role': 'superadmin'});
    expect(user.role, Role.viewer);
    expect(user.spectatorId, isNull);

    final booking = Booking.fromJson({'id': 1, 'status': 'что-то новое'});
    expect(booking.status, BookingStatus.expired);
    expect(booking.isActive, isFalse);
  });

  test('бронь: сумма считается из цены спектакля и числа мест', () {
    final b = Booking.fromJson({
      'id': 5,
      'seats': 3,
      'status': 'active',
      'show': {'id': 7, 'title': 'Гамлет', 'price': 1200},
      'spectator': {'id': 1, 'fullName': 'Иванов Сергей'},
    });
    expect(b.total, 3600);
    expect(b.showTitle, 'Гамлет');
    expect(b.spectatorName, 'Иванов Сергей');
    expect(b.isActive, isTrue);
  });

  test('фильтры из адреса: мусор заменяется значениями по умолчанию', () {
    final q = ListQuery.fromParams({
      'page': '-3',
      'size': '100500',
      'sort': 'password,desc', // поле, по которому сортировать нельзя
    }, sortFields: Genre.sortFields);
    expect(q.page, 1);
    expect(q.sortField, 'name');
    expect(ListQuery.fromParams(q.toParams(), sortFields: Genre.sortFields), q);
  });
}
