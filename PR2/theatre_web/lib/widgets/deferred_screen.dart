import 'package:flutter/material.dart';

/// Экран из отложенной библиотеки (`deferred as`, ПР6). Её код лежит
/// в отдельном файле main.dart.js_N.part.js и скачивается при первом
/// открытии экрана, а не вместе со всем приложением. Так зритель вообще
/// не грузит формы редактирования, кассу и экраны администратора.
class DeferredScreen extends StatefulWidget {
  /// loadLibrary отложенной библиотеки
  final Future<void> Function() load;
  final Widget Function() builder;

  const DeferredScreen({super.key, required this.load, required this.builder});

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        // файл части не скачался — например, пропала сеть
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Не удалось загрузить раздел. Проверьте связь.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => setState(() => _future = widget.load()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        return widget.builder();
      },
    );
  }
}
