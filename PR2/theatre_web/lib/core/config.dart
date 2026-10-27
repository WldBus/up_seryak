/// Адрес сервера задаётся при запуске, а не константой в коде:
/// на занятии он один, дома другой, после публикации третий.
///
///   flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

// Ограничения сессии (ПР5). Тоже задаются при запуске, чтобы на проверке
// не ждать по полчаса:
//   --dart-define=INACTIVITY_SECONDS=60 --dart-define=SESSION_MINUTES=2

/// выход, если столько секунд не было ни одного действия
const inactivityTimeout = Duration(
  seconds: int.fromEnvironment('INACTIVITY_SECONDS', defaultValue: 180),
);

/// за сколько секунд до выхода по неактивности предупредить
const inactivityWarning = Duration(
  seconds: int.fromEnvironment('INACTIVITY_WARNING_SECONDS', defaultValue: 30),
);

/// общая длительность сессии: после неё выход, даже если человек активен
const sessionLimit = Duration(
  minutes: int.fromEnvironment('SESSION_MINUTES', defaultValue: 30),
);
