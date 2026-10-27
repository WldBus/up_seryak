import '../models/app_user.dart';

// Все проверки «кому что можно» собраны в одном месте. Если писать
// user.role == Role.admin прямо в экранах, где-нибудь проверку забудут или
// напишут наоборот, а новую роль придётся дописывать в двадцати местах.
//
// Важно: это удобство интерфейса, а не защита. Проверки только прячут
// кнопки и закрывают адреса. Настоящую проверку делает сервер — он берёт
// роль из подписанного токена и на чужое действие отвечает 403.
//
// Таблица совпадает с правами сервера (КОНТРАКТ-API-театр.md, раздел 2.3).

/// смотреть спектакли, театры, актёров и жанры — любой, кто вошёл
bool canViewCatalog(Role? role) => role != null;

/// создавать, изменять и удалять в корзину спектакли и справочники
bool canEditCatalog(Role? role) => role == Role.cashier || role == Role.admin;

/// раздел «Зрители»
bool canManageSpectators(Role? role) =>
    role == Role.cashier || role == Role.admin;

/// «Мои бронирования» и продление своей брони — только у зрителя
bool canSeeOwnBookings(Role? role) => role == Role.viewer;

bool canExtendBooking(Role? role) => role == Role.viewer;

/// «Касса»: все брони, оформление, выкуп и отмена — только у кассира
bool canUseCashDesk(Role? role) => role == Role.cashier;

/// физическое удаление и восстановление
bool canHardDelete(Role? role) => role == Role.admin;

bool canRestore(Role? role) => role == Role.admin;

/// пользователи и роли
bool canManageUsers(Role? role) => role == Role.admin;

bool canSeeStats(Role? role) => role == Role.admin;
