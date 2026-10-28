'use strict';
/**
 * Хранение данных сервера в PostgreSQL (Supabase).
 *
 * Логика сервера (фильтры, проверки, брони) осталась прежней и работает
 * с объектом db в памяти. Этот модуль только переносит данные между db
 * и таблицами базы:
 *   load() — перед каждым запросом читаю все таблицы, база главная;
 *   save() — после запроса сравниваю db с тем, что загрузил, и записываю
 *            в базу только изменившиеся строки, одной транзакцией.
 * Данных немного (десятки строк), поэтому читать всё каждый раз не страшно,
 * зато правка в Table Editor Supabase сразу видна на сайте.
 *
 * Схема таблиц — db/schema.sql.
 */

const { Pool, types } = require('pg');

// дата спектакля хранится без часового пояса (местное время театра).
// по умолчанию pg превратил бы её в Date по поясу сервера, и время съехало бы
types.setTypeParser(1114, (v) => v.replace(' ', 'T'));
// date (дата выдачи карты) — в том же виде, что и раньше в памяти
types.setTypeParser(1082, (v) => v + 'T00:00:00');
// timestamptz — строкой ISO, как new Date().toISOString() в сервере
const parseTimestamptz = types.getTypeParser(1184);
types.setTypeParser(1184, (v) => parseTimestamptz(v).toISOString());

// поля каждой коллекции, кроме id, createdAt и deletedAt (они есть у всех).
// порядок важен: родительские таблицы раньше дочерних
const FIELDS = {
  theatres: ['name', 'city', 'address', 'hallSeats', 'founded'],
  genres: ['name', 'description'],
  actors: ['lastName', 'firstName', 'country', 'birthYear', 'theatreId'],
  spectators: ['lastName', 'firstName', 'email', 'phone'],
  cards: ['spectatorId', 'number', 'issuedAt', 'discount'],
  shows: ['title', 'code', 'date', 'duration', 'price', 'theatreId', 'seatsTotal', 'seatsAvailable'],
  bookings: ['spectatorId', 'showId', 'seats', 'status', 'extended', 'expiresAt', 'closedAt'],
  users: ['username', 'passwordHash', 'fullName', 'email', 'role', 'spectatorId'],
};
const ORDER = Object.keys(FIELDS);

// связи многие ко многим у спектакля: поле-массив → таблица и её столбец
const LINKS = {
  genreIds: { table: 'show_genres', column: 'genre_id' },
  actorIds: { table: 'show_actors', column: 'actor_id' },
};

const snake = (name) => name.replace(/[A-Z]/g, (c) => '_' + c.toLowerCase());

function columnsOf(collection) {
  return ['id', ...FIELDS[collection], 'createdAt', 'deletedAt'];
}

function valueOf(field, row) {
  const v = row[field];
  // в столбец date кладу только дату, время в нём не хранится
  if (field === 'issuedAt' && typeof v === 'string') return v.slice(0, 10);
  return v === undefined ? null : v;
}

function createStorage(connectionString) {
  const pool = new Pool({
    connectionString,
    // Supabase принимает только подключения по SSL, а локальный PostgreSQL
    // для проверки обычно без него
    ssl: /@(localhost|127\.0\.0\.1)[:/]/.test(connectionString) ? false : { rejectUnauthorized: false },
    max: 5,
  });

  // что лежит в базе после последнего load/save: коллекция → id → JSON строки
  let snapshot = {};
  let savedTokens = new Set();

  function remember(db) {
    snapshot = {};
    for (const c of ORDER) {
      snapshot[c] = new Map(db[c].map((row) => [row.id, JSON.stringify(row)]));
    }
    savedTokens = new Set(db.refreshTokens);
  }

  async function load() {
    const [tables, genres, actors, tokens] = await Promise.all([
      Promise.all(ORDER.map((c) => pool.query(`select * from ${c} order by id`))),
      pool.query('select show_id, genre_id from show_genres order by genre_id'),
      pool.query('select show_id, actor_id from show_actors order by actor_id'),
      pool.query('select token from refresh_tokens'),
    ]);

    const db = { seq: {}, refreshTokens: new Set(tokens.rows.map((r) => r.token)) };
    ORDER.forEach((c, i) => {
      db[c] = tables[i].rows.map((r) => {
        const row = {};
        for (const field of columnsOf(c)) row[field] = r[snake(field)];
        return row;
      });
      db.seq[c] = db[c].reduce((max, row) => Math.max(max, row.id), 0);
    });
    for (const show of db.shows) {
      show.genreIds = genres.rows.filter((r) => r.show_id === show.id).map((r) => r.genre_id);
      show.actorIds = actors.rows.filter((r) => r.show_id === show.id).map((r) => r.actor_id);
    }
    remember(db);
    return db;
  }

  async function save(db) {
    const statements = [];
    const add = (text, values = []) => statements.push({ text, values });

    // удалённые физически строки: сначала дочерние таблицы
    for (const c of [...ORDER].reverse()) {
      const ids = new Set(db[c].map((row) => row.id));
      const gone = [...snapshot[c].keys()].filter((id) => !ids.has(id));
      if (gone.length) add(`delete from ${c} where id = any($1)`, [gone]);
    }

    // новые и изменённые строки
    const inserted = new Set();
    for (const c of ORDER) {
      const columns = columnsOf(c);
      const names = columns.map(snake);
      const sql =
        `insert into ${c} (${names.join(', ')}) values (${names.map((_, i) => '$' + (i + 1)).join(', ')}) ` +
        `on conflict (id) do update set ${names.slice(1).map((n) => `${n} = excluded.${n}`).join(', ')}`;
      for (const row of db[c]) {
        const before = snapshot[c].get(row.id);
        if (before === JSON.stringify(row)) continue;
        if (before === undefined) inserted.add(c);
        add(sql, columns.map((field) => valueOf(field, row)));
        if (c === 'shows') {
          for (const [field, link] of Object.entries(LINKS)) {
            add(`delete from ${link.table} where show_id = $1`, [row.id]);
            for (const linkedId of row[field] || []) {
              add(`insert into ${link.table} (show_id, ${link.column}) values ($1, $2)`, [row.id, linkedId]);
            }
          }
        }
      }
    }

    for (const token of db.refreshTokens) {
      if (!savedTokens.has(token)) add('insert into refresh_tokens (token) values ($1)', [token]);
    }
    const revoked = [...savedTokens].filter((t) => !db.refreshTokens.has(t));
    if (revoked.length) add('delete from refresh_tokens where token = any($1)', [revoked]);

    // id новых строк задаёт сервер — двигаю счётчик, чтобы строки,
    // добавленные в Table Editor, не получили уже занятый номер
    for (const c of inserted) {
      add(`select setval(pg_get_serial_sequence('${c}', 'id'), (select max(id) from ${c}))`);
    }

    if (!statements.length) return 0;
    const client = await pool.connect();
    try {
      await client.query('begin');
      for (const s of statements) await client.query(s.text, s.values);
      await client.query('commit');
    } catch (err) {
      await client.query('rollback').catch(() => {});
      throw err;
    } finally {
      client.release();
    }
    remember(db);
    return statements.length;
  }

  return { load, save };
}

module.exports = { createStorage };
