import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

/// Общий каркас экрана: шапка с переключателем темы и содержимое,
/// ограниченное по ширине, чтобы форма не растягивалась на весь монитор.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 420,
  });

  final String title;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // Обращение к Theme.of подписывает экран на смену темы,
    // поэтому значок на кнопке обновляется сам
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: appSettings.toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          // Прокрутка нужна на низких окнах и при открытой клавиатуре
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
