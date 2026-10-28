# Учебная практика: Flutter Web

Практические работы по УП.04.01. Каждая работа лежит в своей папке.

| Работа | Папка | Что сделано |
|---|---|---|
| ПР1. Маршрутизация, формы и URL как состояние | `PR1/calc_web` | Калькулятор и конвертер валют, go_router, параметры в адресе |
| ПР2. Списки, поиск, фильтрация и пагинация | `PR2/theatre_web` | Бронирование билетов в театр: спектакли и театры, provider, фильтры и страницы в адресе |
| ПР3. Формы, валидация и связанные сущности | `PR2/theatre_web` (тот же проект) | 5 сущностей со связями, формы с проверками, сохранение в localStorage |
| ПР4. Подключение REST API | `PR2/theatre_web` + `api` | Данные с сервера через Dio: свои исключения, журнал запросов, повтор чтения, отмена устаревших запросов, кэш справочников, бронирование билетов, тесты репозитория |
| ПР5. Аутентификация, роли и защита маршрутов | `PR2/theatre_web` + `api` | Вход и регистрация, токены в localStorage, автообновление токена на 401, три роли (зритель, кассир, администратор) со своими экранами, защита адресов через redirect, выход по неактивности и по сроку сессии, тесты прав |
| ПР6. Адаптивная вёрстка, сборка, публикация и тестирование | `PR2/theatre_web` + `.github/workflows` | Раскладка на 360/768/1280/1920, релизная сборка и `--wasm`, отложенная загрузка редких разделов, заставка, публикация на GitHub Pages через Actions, работа без связи с сервером, модульные тесты и тесты виджетов |

## Запуск

Сначала сервер (нужен Node.js 18+). Описание API — в `api/КОНТРАКТ-API-театр.md`.

```bash
cd api
node theatre-server.js --port 8080 --origin http://localhost:5555 --auth
```

С `--auth` сервер проверяет токен и роль (ПР5), без него работает как в ПР4.
`--ttl 60` — токен доступа живёт 60 секунд: так видно автообновление.
Учётные записи: `admin/admin123`, `cashier/cashier123`, `viewer/viewer123`.

Потом клиент — только с фиксированным портом, иначе сервер отклонит запросы (CORS):

```bash
cd PR2/theatre_web
flutter pub get
flutter run -d chrome --web-port=5555
```

Другой адрес сервера: `--dart-define=API_BASE_URL=http://192.168.1.10:8080/api`.
Сроки сессии для проверки: `--dart-define=INACTIVITY_SECONDS=45`
(по умолчанию 180), `INACTIVITY_WARNING_SECONDS` (30), `SESSION_MINUTES` (30).
Проверка, что сервер работает: http://localhost:8080/api/__health. Тесты: `flutter test`.

Нужен Flutter 3.x с поддержкой web.

## Сборка и публикация (ПР6)

```bash
cd PR2/theatre_web
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
flutter build web --release --wasm --base-href /up_seryak/ --dart-define=API_BASE_URL=http://localhost:8080/api
cp build/web/index.html build/web/404.html
```

- `--base-href /up_seryak/` — сайт на GitHub Pages лежит в подпапке с именем репозитория;
- `404.html` — копия `index.html`: Pages отдаёт её на любой неизвестный адрес, и прямая ссылка на внутренний экран открывается, а не даёт 404;
- `--wasm` — собираются два варианта, браузер без WasmGC (Safari) берёт JavaScript.

Публикует всё это сам `.github/workflows/deploy.yml` при каждом push в `main`
(один раз включить: Settings → Pages → Source → GitHub Actions).
Адрес: https://wldbus.github.io/up_seryak/

### Сервер на Render

Опубликованный сайт берёт данные с сервера на Render, а не с моего компьютера:
https://theatre-api-ncpk.onrender.com/api (проверка — `/api/__health`).

Как подключено (Render → New → Web Service, репозиторий `up_seryak`):

- Root Directory: `api`, Runtime: Node, Build Command: `npm install`, Start Command: `npm start`, тариф Free;
- `npm start` (см. `api/package.json`) запускает сервер с `--auth` и списком
  источников для CORS, порт Render передаёт сам в переменной `PORT`;
- в GitHub: Settings → Secrets and variables → Actions → Variables →
  `API_BASE_URL` = `https://theatre-api-ncpk.onrender.com/api`, после этого Actions собирает сайт уже с этим адресом.

Бесплатный сервер засыпает через 15 минут без запросов: первый запрос после
этого ждёт около минуты.

### База данных в Supabase

```
Сайт (GitHub Pages) → API (Render, theatre-server.js) → БД (Supabase, PostgreSQL)
```

Данные хранятся в PostgreSQL в Supabase, поэтому не пропадают, когда сервер засыпает.

- `api/db/schema.sql` — скрипт базы: 11 таблиц (театры, жанры, актёры, спектакли,
  связи спектакль–жанр и спектакль–актёр, зрители, карты, брони, пользователи,
  токены обновления) с внешними ключами, проверками и начальными данными.
  Запуск: Supabase → SQL Editor → вставить файл → Run. Повторный запуск
  пересоздаёт таблицы с начальными данными;
- `api/storage.js` — перед каждым запросом сервер читает таблицы, после запроса
  записывает изменившиеся строки одной транзакцией. Правка в Table Editor
  сразу видна на сайте;
- на Render переменная окружения `DATABASE_URL` = строка подключения Supabase
  (Connect → Session pooler). Пароль базы есть только там, в репозитории его нет.
  Data API в проекте Supabase выключен: в базу ходит только сервер.

Без `DATABASE_URL` сервер, как раньше, хранит данные в памяти и работает без
`npm install` — локально он запускается командой из раздела «Запуск», а сборка
без переменной `API_BASE_URL` обращается к `http://localhost:8080/api`.
Локально с базой: `npm install`, затем
`DATABASE_URL=postgresql://… node theatre-server.js --port 8080 --auth --origin http://localhost:5555`.
