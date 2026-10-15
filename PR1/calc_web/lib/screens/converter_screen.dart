import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/currency.dart';
import '../logic/numbers.dart';
import '../settings/app_settings.dart';
import '../widgets/app_page.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  // Последняя выбранная пара восстанавливается из localStorage
  String _from = appSettings.lastFrom;
  String _to = appSettings.lastTo;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setPair(String from, String to) {
    setState(() {
      _from = from;
      _to = to;
    });
    appSettings.saveCurrencyPair(from, to);
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите сумму';
    final amount = parseNumber(value);
    if (amount == null) return 'Это не число';
    if (amount < 0) return 'Сумма не может быть отрицательной';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri(
      path: '/converter/result',
      queryParameters: {
        'from': _from,
        'to': _to,
        'amount': numberForUrl(_amountController.text),
      },
    );
    context.go(uri.toString());
  }

  Widget _currencyField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: ratesToRub.keys
          .map(
            (code) => DropdownMenuItem(
              value: code,
              child: Text(
                '$code — ${currencyNames[code]}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromField = _currencyField(
      label: 'Из валюты',
      value: _from,
      onChanged: (code) => _setPair(code, _to),
    );
    final toField = _currencyField(
      label: 'В валюту',
      value: _to,
      onChanged: (code) => _setPair(_from, code),
    );

    return AppPage(
      title: 'Конвертер валют',
      maxWidth: 560,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // На широком окне списки стоят в одну строку
                final wide = constraints.maxWidth >= 480;
                final swapButton = IconButton(
                  tooltip: 'Поменять местами',
                  icon: Icon(wide ? Icons.swap_horiz : Icons.swap_vert),
                  onPressed: () => _setPair(_to, _from),
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: fromField),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: swapButton,
                      ),
                      Expanded(child: toField),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    fromField,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: swapButton,
                    ),
                    toField,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
              ),
              validator: _amountValidator,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Конвертировать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
