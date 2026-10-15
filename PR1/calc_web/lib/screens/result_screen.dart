import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calc_result.dart';
import '../logic/numbers.dart';
import '../widgets/app_page.dart';

/// Общий экран результата для калькулятора и конвертера.
/// Всё, что он показывает, получено из параметров адреса.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.expression,
    required this.result,
    required this.backPath,
    this.unit = '',
    this.fractionDigits = 6,
  });

  final String title;

  /// Левая часть равенства, например «12 / 5». Показывается только при успехе.
  final String expression;
  final CalcResult result;

  /// Адрес формы, к которой возвращает кнопка.
  final String backPath;

  /// Единица измерения после числа, например код валюты.
  final String unit;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final result = this.result;

    return AppPage(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // sealed-класс заставляет разобрать оба варианта
          switch (result) {
            CalcSuccess(:final value) => _SuccessCard(
              expression: expression,
              value: '${formatNumber(value, digits: fractionDigits)} $unit'
                  .trim(),
            ),
            CalcFailure(:final message) => _FailureCard(message: message),
          },
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(backPath),
            icon: const Icon(Icons.arrow_back),
            label: Text(
              result is CalcSuccess ? 'Новый расчёт' : 'Вернуться к форме',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('На главную'),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.expression, required this.value});

  final String expression;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '$expression =',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            // Длинное число переносится, а не вылезает за край карточки
            SelectableText(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Не удалось выполнить расчёт',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
