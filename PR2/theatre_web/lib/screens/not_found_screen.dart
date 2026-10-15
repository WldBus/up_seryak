import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  final String location;

  const NotFoundScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('404', style: Theme.of(context).textTheme.displayMedium),
            Text('Страница $location не найдена'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/shows'),
              child: const Text('К спектаклям'),
            ),
          ],
        ),
      ),
    );
  }
}
