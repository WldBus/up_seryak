import 'package:go_router/go_router.dart';

import 'logic/calculator.dart';
import 'logic/currency.dart';
import 'screens/calculator_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'calculator',
          builder: (context, state) => const CalculatorScreen(),
          routes: [
            // Вложенный маршрут: итоговый адрес — /calculator/result
            GoRoute(
              path: 'result',
              builder: (context, state) {
                // Экран результата получает данные только из адреса
                final q = state.uri.queryParameters;
                final op = normalizeOperation(q['op']);
                return ResultScreen(
                  title: 'Результат вычисления',
                  expression: '${q['a']?.trim()} $op ${q['b']?.trim()}',
                  result: calculate(q['a'], q['op'], q['b']),
                  backPath: '/calculator',
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'converter',
          builder: (context, state) => const ConverterScreen(),
          routes: [
            // Итоговый адрес — /converter/result
            GoRoute(
              path: 'result',
              builder: (context, state) {
                final q = state.uri.queryParameters;
                return ResultScreen(
                  title: 'Результат конвертации',
                  expression:
                      '${q['amount']?.trim()} ${q['from']?.trim().toUpperCase()}',
                  result: convert(q['from'], q['to'], q['amount']),
                  unit: q['to']?.trim().toUpperCase() ?? '',
                  fractionDigits: 4,
                  backPath: '/converter',
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
  // Аналог страницы 404: сюда попадают все неизвестные адреса
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);
