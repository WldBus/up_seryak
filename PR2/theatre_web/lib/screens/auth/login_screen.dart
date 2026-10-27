import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/validators.dart';
import '../../state/auth_notifier.dart';
import 'auth_layout.dart';

/// Вход. После успешного входа никуда переходить не нужно: маршрутизатор
/// сам заметит смену сессии (refreshListenable) и откроет адрес из from
/// или главную.
class LoginScreen extends StatefulWidget {
  /// куда человек шёл, когда его отправили на вход
  final String? from;

  const LoginScreen({super.key, this.from});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthNotifier>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.login(_username.text.trim(), _password.text);
    } on UnauthorizedException catch (e) {
      // неверный логин или пароль — сообщение сервера
      if (mounted) setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = context.watch<AuthNotifier>().message;
    final from = widget.from;

    return AuthLayout(
      title: 'Вход',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reason != null) AuthMessage(reason, error: false),
            if (from != null && reason == null)
              const AuthMessage(
                'Чтобы открыть эту страницу, войдите в систему.',
                error: false,
              ),
            if (_error != null) AuthMessage(_error!),
            TextFormField(
              controller: _username,
              enabled: !_saving,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: V.required('Укажите логин'),
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<AuthNotifier>().clearMessage(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_saving,
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Показать пароль' : 'Скрыть пароль',
                  icon: Icon(
                    _hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: V.required('Укажите пароль'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Войти'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => context.go(
                      from == null
                          ? '/register'
                          : '/register?from=${Uri.encodeComponent(from)}',
                    ),
              child: const Text('Нет учётной записи? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
