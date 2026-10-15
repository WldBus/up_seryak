import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calculator.dart';
import '../logic/numbers.dart';
import '../widgets/app_page.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  String _operation = '+';

  static const _operationNames = {
    '+': 'сложение',
    '-': 'вычитание',
    '*': 'умножение',
    '/': 'деление',
  };

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    if (parseNumber(value) == null) return 'Это не число';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Аналог redirect после @PostMapping:
    // данные уходят в адрес, а расчёт выполняет экран результата.
    // Uri сам кодирует параметры, поэтому «+» превращается в %2B,
    // а не в пробел.
    final uri = Uri(
      path: '/calculator/result',
      queryParameters: {
        'a': numberForUrl(_aController.text),
        'op': _operation,
        'b': numberForUrl(_bController.text),
      },
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Калькулятор',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _aController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Первое число',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _operation,
              decoration: const InputDecoration(
                labelText: 'Операция',
                border: OutlineInputBorder(),
              ),
              items: operations
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text('$o  ${_operationNames[o]}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _operation = value ?? '+'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Второе число',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Вычислить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
