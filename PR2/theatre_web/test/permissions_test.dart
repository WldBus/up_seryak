import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_web/core/permissions.dart';
import 'package:theatre_web/core/router.dart';
import 'package:theatre_web/models/app_user.dart';

// Права проверяю таблицей: для каждой операции — у каких ролей она есть.
// Таблица та же, что в отчёте и в контракте сервера (раздел 2.3).

const viewer = Role.viewer;
const cashier = Role.cashier;
const admin = Role.admin;

void main() {
  final table = <String, (bool Function(Role?), Set<Role>)>{
    'смотреть каталог': (canViewCatalog, {viewer, cashier, admin}),
    'править каталог': (canEditCatalog, {cashier, admin}),
    'раздел «Зрители»': (canManageSpectators, {cashier, admin}),
    'мои бронирования': (canSeeOwnBookings, {viewer}),
    'продлить бронь': (canExtendBooking, {viewer}),
    'касса': (canUseCashDesk, {cashier}),
    'удалить навсегда': (canHardDelete, {admin}),
    'восстановить': (canRestore, {admin}),
    'пользователи и роли': (canManageUsers, {admin}),
    'статистика': (canSeeStats, {admin}),
  };

  group('права по ролям', () {
    for (final MapEntry(key: name, value: (check, allowed)) in table.entries) {
      test(name, () {
        for (final role in Role.values) {
          expect(
            check(role),
            allowed.contains(role),
            reason: '$name для роли ${role.label}',
          );
        }
      });
    }
  });

  test('гость (не вошёл) не может ничего', () {
    for (final (check, _) in table.values) {
      expect(check(null), isFalse);
    }
  });

  test('зритель не может ни править каталог, ни удалять', () {
    expect(canEditCatalog(viewer), isFalse);
    expect(canHardDelete(viewer), isFalse);
    expect(canRestore(viewer), isFalse);
  });

  test('у каждой роли есть раздел, которого нет у остальных', () {
    expect(canSeeOwnBookings(viewer), isTrue);
    expect(canSeeOwnBookings(cashier) || canSeeOwnBookings(admin), isFalse);

    expect(canUseCashDesk(cashier), isTrue);
    expect(canUseCashDesk(viewer) || canUseCashDesk(admin), isFalse);

    expect(canManageUsers(admin), isTrue);
    expect(canManageUsers(viewer) || canManageUsers(cashier), isFalse);
  });

  test('администратор не работает в кассе — роли не вложены', () {
    expect(canUseCashDesk(admin), isFalse);
    expect(canSeeOwnBookings(admin), isFalse);
  });

  test('после входа возвращаем только на свои адреса', () {
    expect(safeFrom('/shows?page=2'), '/shows?page=2');
    expect(safeFrom('https://evil.example'), isNull);
    expect(safeFrom('//evil.example'), isNull);
    expect(safeFrom('/login'), isNull);
    expect(safeFrom('/forbidden?from=/users'), isNull);
  });

  test('незнакомая роль с сервера считается зрителем', () {
    expect(Role.fromCode('admin'), admin);
    expect(Role.fromCode('cashier'), cashier);
    expect(Role.fromCode('superuser'), viewer);
    expect(Role.fromCode(null), viewer);
    expect(canManageUsers(Role.fromCode('ADMIN')), isFalse);
  });
}
