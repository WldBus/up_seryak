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

Сервер остаётся локальным. Чтобы опубликованный сайт его видел, в `--origin`
добавляется адрес Pages (источников можно несколько через запятую):

```bash
node theatre-server.js --port 8080 --auth --origin http://localhost:5555,http://localhost:8000,https://wldbus.github.io
```

Chrome разрешает странице с HTTPS обращаться к `http://localhost` (это не считается
смешанным содержимым), но может один раз спросить разрешение на доступ к локальной сети.
