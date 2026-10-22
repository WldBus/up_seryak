#!/usr/bin/env node
/**
 * Мок-сервер API «Театральная касса».
 *
 * Сделан по образцу учебного mock-server.js («Библиотека»): те же правила,
 * коды ответов, CORS и учебные параметры, только ресурсы про театр.
 * Описание — в файле КОНТРАКТ-API-театр.md.
 * Зависимостей нет — нужен только Node.js 18 или новее.
 *
 *   node theatre-server.js --port 8080 --origin http://localhost:5555
 *   node theatre-server.js --port 8080 --origin http://localhost:5555 --auth
 *
 * Без --auth права не проверяются (так в ПР4, вход появится в ПР5).
 *
 * Данные хранятся в памяти и сбрасываются при перезапуске
 * либо запросом POST /api/__reset
 *
 * Учебные возможности:
 *   ?__delay=1500   задержка ответа в миллисекундах (проверка индикатора загрузки)
 *   ?__fail=500     принудительный код ошибки (проверка обработки ошибок)
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

// ─────────────────────────── параметры запуска ───────────────────────────

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const AUTH = args.includes('--auth');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900)); // секунд
const REFRESH_TTL = 60 * 60 * 24 * 7;

// ─────────────────────────────── токены ───────────────────────────────

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

// ─────────────────────────────── данные ───────────────────────────────

let db;

function seed() {
  db = {
    seq: {},
    theatres: [],
    genres: [],
    actors: [],
    shows: [],
    spectators: [],
    cards: [],
    bookings: [],
    users: [],
    refreshTokens: new Set(),
  };

  const T = (name, city, address, hallSeats, founded) =>
    push('theatres', { name, city, address, hallSeats, founded });
  const G = (name, description) => push('genres', { name, description });
  const A = (lastName, firstName, country, birthYear, theatreId) =>
    push('actors', { lastName, firstName, country, birthYear, theatreId });

  T('Большой театр', 'Москва', 'Театральная пл., 1', 1740, 1776);
  T('Малый театр', 'Москва', 'Театральный пр., 1', 950, 1756);
  T('МХТ им. Чехова', 'Москва', 'Камергерский пер., 3', 1300, 1898);
  T('Ленком Марка Захарова', 'Москва', 'ул. Малая Дмитровка, 6', 750, 1927);
  T('Театр на Таганке', 'Москва', 'ул. Земляной Вал, 76', 600, 1946);
  T('Мариинский театр', 'Санкт-Петербург', 'Театральная пл., 1', 1625, 1783);
  T('Александринский театр', 'Санкт-Петербург', 'пл. Островского, 6', 1378, 1756);
  T('НОВАТ', 'Новосибирск', 'Красный пр., 36', 1774, 1945);
  T('Театр им. Качалова', 'Казань', 'ул. Баумана, 48', 650, 1791);
  T('Театр драмы им. Горького', 'Ростов-на-Дону', 'Театральная пл., 1', 1200, 1863);

  G('Драма', 'Серьёзный сюжет о конфликте человека с обществом или собой');
  G('Комедия', 'Весёлое представление со счастливым финалом');
  G('Опера', 'Музыкально-драматическое произведение, где текст поётся');
  G('Балет', 'Сюжет передаётся танцем и музыкой');
  G('Мюзикл', 'Сочетание диалогов, песен и танцев');
  G('Трагедия', 'Неразрешимый конфликт и гибель героя');
  G('Детский', 'Спектакли для зрителей младшего возраста');

  // имена выдуманные; у театра N в труппе актёры 2N-1 и 2N
  A('Орлова', 'Анна', 'Россия', 1990, 1);
  A('Соколов', 'Игорь', 'Россия', 1985, 1);
  A('Миронова', 'Елена', 'Россия', 1978, 2);
  A('Громов', 'Павел', 'Россия', 1982, 2);
  A('Ланская', 'Мария', 'Россия', 1993, 3);
  A('Ветров', 'Олег', 'Беларусь', 1975, 3);
  A('Белова', 'Ирина', 'Россия', 1988, 4);
  A('Карпов', 'Денис', 'Россия', 1991, 4);
  A('Зорина', 'Ольга', 'Казахстан', 1984, 5);
  A('Ершов', 'Михаил', 'Россия', 1970, 5);
  A('Светлова', 'Дарья', 'Россия', 1996, 6);
  A('Ильин', 'Артём', 'Россия', 1989, 6);
  A('Руднева', 'Татьяна', 'Россия', 1981, 7);
  A('Носов', 'Кирилл', 'Россия', 1994, 7);
  A('Данилова', 'Ксения', 'Россия', 1992, 8);
  A('Фролов', 'Виктор', 'Россия', 1979, 8);
  A('Гарипова', 'Алсу', 'Россия', 1990, 9);
  A('Хайруллин', 'Рустам', 'Россия', 1983, 9);
  A('Левченко', 'Юлия', 'Украина', 1987, 10);
  A('Степанов', 'Роман', 'Россия', 1976, 10);

  // дата спектакля — местное время театра, поэтому без часового пояса
  const S = (id, title, theatreId, genreIds, date, duration, price, total, available) =>
    push('shows', {
      title,
      code: 'SP-' + (1000 + id),
      date,
      duration,
      price,
      theatreId,
      genreIds,
      actorIds: id % 2 === 0 ? [theatreId * 2 - 1, theatreId * 2] : [theatreId * 2 - 1],
      seatsTotal: total,
      seatsAvailable: available,
    });

  S(1, 'Лебединое озеро', 1, [4], '2026-11-02T19:00:00', 165, 6500, 400, 12);
  S(2, 'Евгений Онегин', 1, [3], '2026-11-05T19:00:00', 180, 5200, 400, 85);
  S(3, 'Щелкунчик', 6, [4, 7], '2026-12-28T12:00:00', 120, 4800, 350, 0);
  S(4, 'Горе от ума', 2, [2], '2026-11-08T18:30:00', 170, 2400, 300, 140);
  S(5, 'Ревизор', 2, [2], '2026-11-14T19:00:00', 150, 2100, 300, 96);
  S(6, 'Чайка', 3, [1], '2026-11-03T19:00:00', 190, 3500, 250, 40);
  S(7, 'Вишнёвый сад', 3, [1, 2], '2026-11-20T19:00:00', 200, 3800, 250, 18);
  S(8, 'Юнона и Авось', 4, [5], '2026-11-11T19:00:00', 110, 4200, 200, 7);
  S(9, 'Женитьба Фигаро', 4, [2], '2026-11-25T19:00:00', 160, 3300, 200, 64);
  S(10, 'Мастер и Маргарита', 5, [1], '2026-11-06T19:00:00', 230, 2900, 180, 22);
  S(11, 'Добрый человек из Сезуана', 5, [1], '2026-12-04T19:00:00', 175, 2500, 180, 75);
  S(12, 'Жизель', 6, [4], '2026-11-16T19:00:00', 125, 5600, 350, 110);
  S(13, 'Борис Годунов', 6, [3, 6], '2026-12-09T19:00:00', 195, 5900, 350, 160);
  S(14, 'Гамлет', 7, [6], '2026-11-13T19:00:00', 200, 2700, 280, 30);
  S(15, 'Маскарад', 7, [1, 6], '2026-12-12T19:00:00', 185, 2600, 280, 120);
  S(16, 'Кармен', 8, [3], '2026-11-22T18:00:00', 190, 2300, 450, 210);
  S(17, 'Спящая красавица', 8, [4, 7], '2026-12-30T12:00:00', 150, 2000, 450, 5);
  S(18, 'Гроза', 9, [1, 6], '2026-11-19T18:30:00', 160, 1500, 220, 88);
  S(19, 'Золушка', 9, [7], '2026-12-27T11:00:00', 90, 900, 220, 150);
  S(20, 'Ромео и Джульетта', 10, [6], '2026-11-28T18:00:00', 170, 1800, 260, 33);
  S(21, 'Нотр-Дам де Пари', 10, [5], '2026-12-18T19:00:00', 160, 3100, 260, 0);
  S(22, 'Пиковая дама', 1, [3, 6], '2026-12-06T19:00:00', 185, 5800, 400, 47);
  S(23, 'Три сестры', 3, [1], '2026-12-15T19:00:00', 210, 3200, 250, 61);
  S(24, 'Буратино', 4, [7, 5], '2026-12-21T12:00:00', 80, 1200, 200, 120);

  const spectators = [
    ['Иванов', 'Сергей', 'ivanov@mail.ru', '+79161234567', '100001', '2024-03-12', 5],
    ['Петрова', 'Наталья', 'petrova@yandex.ru', '+79032223344', '100002', '2024-09-01', 10],
    ['Кузнецов', 'Андрей', 'kuznetsov@gmail.com', '+79265556677', '100003', '2025-01-20', 0],
    ['Смирнова', 'Ольга', 'smirnova@mail.ru', '+79857778899', '100004', '2025-05-14', 15],
    ['Попов', 'Дмитрий', 'popov@inbox.ru', '+79101112233', '100005', '2025-08-03', 5],
    ['Васильева', 'Екатерина', 'vasilyeva@yandex.ru', '+79209998877', '100006', '2025-11-27', 20],
    ['Новиков', 'Алексей', 'novikov@gmail.com', '+79994445566', '100007', '2026-02-09', 0],
    ['Морозова', 'Анастасия', 'morozova@mail.ru', '+79176663322', '100008', '2026-06-18', 10],
  ];
  for (const [lastName, firstName, email, phone, number, issuedAt, discount] of spectators) {
    const spectatorId = push('spectators', { lastName, firstName, email, phone });
    push('cards', { spectatorId, number, issuedAt: issuedAt + 'T00:00:00', discount });
  }

  // пара броней, чтобы список не был пустым
  push('bookings', { spectatorId: 1, showId: 2, seats: 2 });
  push('bookings', { spectatorId: 2, showId: 6, seats: 1 });

  push('users', { username: 'admin', passwordHash: hash('admin123'), fullName: 'Администратор', role: 'admin' });
  push('users', { username: 'cashier', passwordHash: hash('cashier123'), fullName: 'Кассир Петрова А. С.', role: 'cashier' });
  push('users', { username: 'viewer', passwordHash: hash('viewer123'), fullName: 'Зритель Иванов С.', role: 'viewer' });
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

const byId = (collection, id) => db[collection].find((x) => x.id === Number(id));

// ──────────────────────── развёртывание объектов ────────────────────────

const fullName = (p) => `${p.lastName} ${p.firstName}`;

// на запись приходят theatreId, genreIds, actorIds, а отдаются развёрнутые
// объекты — так же, как у книги в учебном API
function expandShow(s) {
  const theatre = byId('theatres', s.theatreId);
  return {
    id: s.id,
    title: s.title,
    code: s.code,
    date: s.date,
    duration: s.duration,
    price: s.price,
    theatre: theatre ? { id: theatre.id, name: theatre.name } : null,
    genres: s.genreIds
      .map((id) => byId('genres', id))
      .filter(Boolean)
      .map((g) => ({ id: g.id, name: g.name })),
    actors: s.actorIds
      .map((id) => byId('actors', id))
      .filter(Boolean)
      .map((a) => ({ id: a.id, fullName: fullName(a) })),
    seatsTotal: s.seatsTotal,
    seatsAvailable: s.seatsAvailable,
    createdAt: s.createdAt,
    deletedAt: s.deletedAt,
  };
}

function expandSpectator(s) {
  const card = db.cards.find((c) => c.spectatorId === s.id);
  return {
    id: s.id,
    lastName: s.lastName,
    firstName: s.firstName,
    email: s.email,
    phone: s.phone,
    card: card
      ? { id: card.id, number: card.number, issuedAt: card.issuedAt, discount: card.discount }
      : null,
    createdAt: s.createdAt,
    deletedAt: s.deletedAt,
  };
}

function expandBooking(b) {
  const spectator = byId('spectators', b.spectatorId);
  const show = byId('shows', b.showId);
  return {
    id: b.id,
    spectator: spectator ? { id: spectator.id, fullName: fullName(spectator) } : null,
    show: show ? { id: show.id, title: show.title, date: show.date } : null,
    seats: b.seats,
    createdAt: b.createdAt,
    deletedAt: b.deletedAt,
  };
}

function expandUser(u) {
  return { id: u.id, username: u.username, fullName: u.fullName, role: u.role };
}

const EXPANDERS = {
  shows: expandShow,
  spectators: expandSpectator,
  bookings: expandBooking,
  theatres: (t) => t,
  genres: (g) => g,
  actors: (a) => a,
};

// ─────────────────────────── общие операции ───────────────────────────

function searchableText(collection, item) {
  switch (collection) {
    case 'shows': return [item.title, item.code].join(' ');
    case 'theatres': return [item.name, item.city].join(' ');
    case 'actors': return [item.lastName, item.firstName, item.country].join(' ');
    case 'genres': return [item.name, item.description].join(' ');
    case 'spectators': {
      const card = db.cards.find((c) => c.spectatorId === item.id);
      return [item.lastName, item.firstName, item.email, card ? card.number : ''].join(' ');
    }
    default: return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) => searchableText(collection, x).toLowerCase().includes(needle));
  }

  if (collection === 'shows') {
    if (q.genreId) result = result.filter((s) => s.genreIds.includes(Number(q.genreId)));
    if (q.theatreId) result = result.filter((s) => s.theatreId === Number(q.theatreId));
    if (q.actorId) result = result.filter((s) => s.actorIds.includes(Number(q.actorId)));
    if (q.priceFrom) result = result.filter((s) => s.price >= Number(q.priceFrom));
    if (q.priceTo) result = result.filter((s) => s.price <= Number(q.priceTo));
  }

  if (collection === 'actors' && q.theatreId) {
    result = result.filter((a) => a.theatreId === Number(q.theatreId));
  }

  if (collection === 'bookings') {
    if (q.showId) result = result.filter((b) => b.showId === Number(q.showId));
    if (q.spectatorId) result = result.filter((b) => b.spectatorId === Number(q.spectatorId));
  }

  return result;
}

// скидка лежит в карте, а не в самом зрителе
function sortValue(collection, row, field) {
  if (collection === 'spectators' && field === 'discount') {
    const card = db.cards.find((c) => c.spectatorId === row.id);
    return card ? card.discount : null;
  }
  return row[field];
}

function applySort(collection, rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = sortValue(collection, a, field);
    const bv = sortValue(collection, b, field);
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

// ─────────────────────────────── валидация ───────────────────────────────

// те же правила, что в формах клиента (таблица проверок полей в отчёте ПР3).
// клиент проверяет сразу, а сервер — ещё раз, потому что клиента можно обойти
function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');
  const int = (v) => (Number.isInteger(Number(v)) && v !== '' && v != null ? Number(v) : null);
  const year = new Date().getFullYear();
  const letters = /^[A-Za-zА-Яа-яЁё\s-]+$/;
  const others = (rows) => rows.filter((x) => x.id !== id);

  const text = (key, label, min, max, onlyLetters = false) => {
    const v = str(body[key]);
    if (!v) e[key] = `Укажите ${label}`;
    else if (v.length < min) e[key] = `Не короче ${min} символов`;
    else if (v.length > max) e[key] = `Не длиннее ${max} символов`;
    else if (onlyLetters && !letters.test(v)) e[key] = 'Только буквы, пробел и дефис';
  };
  const number = (key, min, max, message) => {
    const v = int(body[key]);
    if (v == null || v < min || v > max) e[key] = message;
  };
  const date = (key, message) => {
    if (!str(body[key]) || Number.isNaN(Date.parse(body[key]))) e[key] = message;
  };

  if (collection === 'shows') {
    text('title', 'название', 2, 100);

    const code = str(body.code).toUpperCase();
    if (!code) e.code = 'Укажите код';
    else if (!/^SP-\d{4}$/.test(code)) e.code = 'Формат кода: SP-0000';
    else if (others(db.shows).some((s) => s.code.toUpperCase() === code)) {
      e.code = `Спектакль с кодом ${code} уже есть`;
    }

    const theatre = byId('theatres', body.theatreId);
    if (!theatre || theatre.deletedAt) e.theatreId = 'Театр не найден';

    const actorIds = Array.isArray(body.actorIds) ? body.actorIds.map(Number) : [];
    if (!actorIds.length) e.actorIds = 'Выберите хотя бы одного актёра';
    else {
      const wrong = actorIds.map((a) => byId('actors', a)).find((a) => !a || a.deletedAt || (theatre && a.theatreId !== theatre.id));
      if (wrong !== undefined) e.actorIds = 'Можно выбрать только актёров из труппы этого театра';
    }

    const genreIds = Array.isArray(body.genreIds) ? body.genreIds.map(Number) : [];
    if (!genreIds.length) e.genreIds = 'Выберите хотя бы один жанр';
    else if (genreIds.some((g) => !byId('genres', g) || byId('genres', g).deletedAt)) e.genreIds = 'Жанр не найден';

    date('date', 'Укажите дату показа');
    number('duration', 30, 300, 'Длительность от 30 до 300 минут');
    number('price', 1, 50000, 'Цена больше нуля и не больше 50000');
    number('seatsTotal', 1, 5000, 'Мест больше нуля и не больше 5000');
    const total = int(body.seatsTotal);
    const free = int(body.seatsAvailable);
    if (free == null || free < 0) e.seatsAvailable = 'Свободных мест — целое, не меньше нуля';
    else if (total != null && free > total) e.seatsAvailable = 'Свободных мест не может быть больше, чем всего';
  }

  if (collection === 'theatres') {
    text('name', 'название', 2, 80);
    text('city', 'город', 2, 50, true);
    text('address', 'адрес', 5, 120);
    number('hallSeats', 1, 10000, 'Мест в зале больше нуля и не больше 10000');
    number('founded', 1500, year, `Год основания от 1500 до ${year}`);
    if (!e.name && !e.city) {
      const dup = others(db.theatres).some(
        (t) => t.name.toLowerCase() === str(body.name).toLowerCase() && t.city.toLowerCase() === str(body.city).toLowerCase(),
      );
      if (dup) e.name = `В городе ${str(body.city)} уже есть театр с таким названием`;
    }
  }

  if (collection === 'genres') {
    text('name', 'название', 2, 40, true);
    if (str(body.description).length > 300) e.description = 'Не длиннее 300 символов';
    if (!e.name && others(db.genres).some((g) => g.name.toLowerCase() === str(body.name).toLowerCase())) {
      e.name = `Жанр «${str(body.name)}» уже есть`;
    }
  }

  if (collection === 'actors') {
    text('lastName', 'фамилию', 2, 50, true);
    text('firstName', 'имя', 2, 50, true);
    text('country', 'страну', 2, 50, true);
    number('birthYear', 1900, year - 10, `Год рождения от 1900 до ${year - 10}`);
    const theatre = byId('theatres', body.theatreId);
    if (!theatre || theatre.deletedAt) e.theatreId = 'Театр не найден';
  }

  if (collection === 'spectators') {
    text('lastName', 'фамилию', 2, 50, true);
    text('firstName', 'имя', 2, 50, true);

    const email = str(body.email);
    if (!email) e.email = 'Укажите почту';
    else if (email.length > 100) e.email = 'Не длиннее 100 символов';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) e.email = 'Некорректный адрес почты';
    else if (others(db.spectators).some((s) => s.email.toLowerCase() === email.toLowerCase())) {
      e.email = `Зритель с почтой ${email} уже зарегистрирован`;
    }

    if (!/^\+7\d{10}$/.test(str(body.phone).replace(/[\s()-]/g, ''))) {
      e.phone = 'Телефон в формате +7 и 10 цифр, например +79161234567';
    }

    // ключи с точкой — это поля из группы «Карта зрителя» в форме
    const card = body.card && typeof body.card === 'object' ? body.card : {};
    const cardNumber = str(card.number);
    if (!/^\d{6}$/.test(cardNumber)) e['card.number'] = 'Номер карты — ровно 6 цифр';
    else if (db.cards.some((c) => c.number === cardNumber && c.spectatorId !== id)) {
      e['card.number'] = `Карта с номером ${cardNumber} уже выдана`;
    }
    if (!str(card.issuedAt) || Number.isNaN(Date.parse(card.issuedAt))) e['card.issuedAt'] = 'Укажите дату выдачи';
    const discount = int(card.discount);
    if (discount == null || discount < 0 || discount > 50) e['card.discount'] = 'Скидка от 0 до 50 %';
  }

  return e;
}

// почему запись нельзя удалить: на неё ссылаются другие. null — можно.
// удалённые спектакли тоже считаются: их могут восстановить
function deleteBlockReason(collection, id, hard) {
  if (collection === 'theatres') {
    const shows = db.shows.filter((s) => s.theatreId === id).length;
    const actors = db.actors.filter((a) => a.theatreId === id).length;
    if (shows || actors) {
      return `Театр «${byId('theatres', id).name}» нельзя удалить: на него ссылаются ` +
        `спектакли (${shows}) и актёры труппы (${actors}). Сначала перенесите их в другой театр или удалите.`;
    }
  }
  if (collection === 'genres') {
    const shows = db.shows.filter((s) => s.genreIds.includes(id)).length;
    if (shows) return `Жанр «${byId('genres', id).name}» нельзя удалить: он указан у спектаклей (${shows}).`;
  }
  if (collection === 'actors') {
    const shows = db.shows.filter((s) => s.actorIds.includes(id)).length;
    if (shows) return `Актёра «${fullName(byId('actors', id))}» нельзя удалить: он занят в спектаклях (${shows}).`;
  }
  if (hard && collection === 'shows') {
    const bookings = db.bookings.filter((b) => b.showId === id && !b.deletedAt).length;
    if (bookings) return `На спектакль есть бронирования (${bookings}), удалить его физически нельзя.`;
  }
  if (hard && collection === 'spectators') {
    const bookings = db.bookings.filter((b) => b.spectatorId === id && !b.deletedAt).length;
    if (bookings) return `У зрителя есть бронирования (${bookings}), удалить его физически нельзя.`;
  }
  return null;
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'shows':
      return {
        title: str(body.title),
        code: str(body.code).toUpperCase(),
        date: str(body.date),
        duration: num(body.duration),
        price: num(body.price),
        theatreId: num(body.theatreId),
        genreIds: ids(body.genreIds),
        actorIds: ids(body.actorIds),
        seatsTotal: num(body.seatsTotal),
        seatsAvailable: num(body.seatsAvailable),
      };
    case 'theatres':
      return {
        name: str(body.name),
        city: str(body.city),
        address: str(body.address),
        hallSeats: num(body.hallSeats),
        founded: num(body.founded),
      };
    case 'genres':
      return { name: str(body.name), description: str(body.description) };
    case 'actors':
      return {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        country: str(body.country),
        birthYear: num(body.birthYear),
        theatreId: num(body.theatreId),
      };
    case 'spectators':
      return {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        email: str(body.email),
        phone: str(body.phone).replace(/[\s()-]/g, ''),
      };
    default:
      return { ...body };
  }
}

// карта зрителя хранится отдельно (один к одному), но пишется вместе с ним
function saveCard(spectatorId, card) {
  const data = {
    number: String(card.number).trim(),
    issuedAt: String(card.issuedAt).trim(),
    discount: Number(card.discount),
  };
  const existing = db.cards.find((c) => c.spectatorId === spectatorId);
  if (existing) Object.assign(existing, data);
  else push('cards', { spectatorId, ...data });
}

// ──────────────────────────── HTTP-обвязка ────────────────────────────

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

function invalid(res, errors) {
  send(res, 422, { message: 'Ошибка валидации', errors });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null; // признак некорректного JSON
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

const ROLE_LEVEL = { viewer: 1, cashier: 2, admin: 3 };

// без флага --auth пропускаем всех (ПР4); с ним проверяем роль (ПР5)
function requireRole(res, user, minRole) {
  if (!AUTH) return true;
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = ['shows', 'theatres', 'actors', 'genres', 'spectators', 'bookings'];

// ─────────────────────────────── маршруты ───────────────────────────────

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  // учебный переключатель поведения
  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  // ── служебные ──
  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  // ── аутентификация (понадобится в ПР5) ──
  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const found = db.users.find((u) => u.username === String(body.username || '').trim() && !u.deletedAt);
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');

    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  // ── бронирование билетов (аналог выдачи книги) ──
  if (path === '/api/bookings' && method === 'POST') {
    if (!requireRole(res, user, 'cashier')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const spectator = byId('spectators', body.spectatorId);
    const show = byId('shows', body.showId);
    if (!spectator || spectator.deletedAt) errors.spectatorId = 'Зритель не найден';
    if (!show || show.deletedAt) errors.showId = 'Спектакль не найден';
    const seats = Number(body.seats || 1);
    if (!Number.isInteger(seats) || seats < 1 || seats > 10) errors.seats = 'От 1 до 10 билетов';
    if (Object.keys(errors).length) return invalid(res, errors);

    if (show.seatsAvailable < seats) {
      return fail(res, 409, show.seatsAvailable === 0
        ? `На спектакль «${show.title}» свободных мест нет`
        : `На спектакль «${show.title}» осталось мест: ${show.seatsAvailable}, а запрошено ${seats}`);
    }

    const id = push('bookings', { spectatorId: spectator.id, showId: show.id, seats });
    show.seatsAvailable -= seats;
    return send(res, 201, expandBooking(byId('bookings', id)));
  }

  // ── единообразный CRUD ──
  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection) || collection === 'bookings') return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'cashier')) return;

    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) return invalid(res, { ids: 'Передайте непустой список идентификаторов' });

    // если хоть одну запись удалить нельзя — не удаляем ничего
    for (const id of ids) {
      if (!byId(collection, id)) continue;
      const reason = deleteBlockReason(collection, id, false);
      if (reason) return fail(res, 409, reason);
    }

    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  const m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];

    // брони только создаются и читаются
    if (collection === 'bookings' && method !== 'GET') {
      return fail(res, 405, 'Бронирования можно только создавать и просматривать');
    }

    // восстановление
    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = byId(collection, id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    // список
    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);
      rows = applyFilters(collection, rows, q);
      rows = applySort(collection, rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    // одна запись
    if (id !== null && method === 'GET') {
      const row = db[collection].find((x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt));
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    // создание
    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'cashier')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const errors = validate(collection, body);
      if (Object.keys(errors).length) return invalid(res, errors);

      const newId = push(collection, normalize(collection, body));
      if (collection === 'spectators') saveCard(newId, body.card);
      return send(res, 201, expand(byId(collection, newId)));
    }

    // изменение
    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'cashier')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');

      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return invalid(res, errors);

      Object.assign(row, normalize(collection, merged));
      if (collection === 'spectators' && merged.card) saveCard(id, merged.card);
      return send(res, 200, expand(row));
    }

    // удаление
    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'cashier')) return;

      const index = db[collection].findIndex((x) => x.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');

      const reason = deleteBlockReason(collection, id, hard);
      if (reason) return fail(res, 409, reason);

      if (hard) {
        db[collection].splice(index, 1);
        if (collection === 'spectators') db.cards = db.cards.filter((c) => c.spectatorId !== id);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

// ─────────────────────────────── запуск ───────────────────────────────

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  // Предварительный запрос браузера. Без этого обработчика на web
  // не заработает ни PUT/DELETE, ни POST с JSON, ни запрос с Authorization.
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(`${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`);
});

server.listen(PORT, () => {
  console.log('');
  console.log('  API «Театральная касса»');
  console.log(`  Адрес:                http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log(`  Проверка прав:        ${AUTH ? 'включена (--auth)' : 'выключена'}`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123   cashier/cashier123   viewer/viewer123');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Задержка ответа: любой запрос с ?__delay=1500');
  console.log('  Ошибка по требованию: любой запрос с ?__fail=500');
  console.log('');
});
