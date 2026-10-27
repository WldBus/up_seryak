import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/validators.dart';
import '../../state/auth_notifier.dart';
import 'auth_layout.dart';

/// Регистрация. Новый пользователь всегда получает роль «Зритель» — это
/// решает сервер. Пароль уходит как есть: хеширует его сервер (хеш на
/// клиенте просто стал бы новым паролем).
class RegisterScreen extends StatefulWidget {
  final String? from;

  const RegisterScreen({super.key, this.from});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _hidePassword = true;
  bool _saving = false;
  String? _error;

  /// ошибки сервера по полям (логин занят и т. п.)
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    // список правил под паролем обновляется на каждую букву
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_fullName, _email, _username, _password, _repeat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthNotifier>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.register(
        username: _username.text.trim(),
        password: _password.text,
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
      );
      // после регистрации сразу вход, маршрутизатор откроет главную
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = Map.of(e.errors));
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// обычная проверка, а если её нет — ошибка сервера по этому полю
  Validator _field(String key, Validator local) =>
      (v) => local(v) ?? _serverErrors[key];

  @override
  Widget build(BuildContext context) {
    final from = widget.from;
    final password = _password.text;

    return AuthLayout(
      title: 'Регистрация',
      child: Form(
        key: _formKey,
        // проверка по мере ввода, а не только по кнопке
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthMessage(_error!),
            _input(
              _fullName,
              'Имя и фамилия',
              Icons.badge_outlined,
              _field(
                'fullName',
                V.combine([V.required('Укажите имя'), V.length(min: 2)]),
              ),
            ),
            _input(
              _email,
              'Электронная почта',
              Icons.alternate_email,
              _field(
                'email',
                V.combine([V.required('Укажите почту'), V.email()]),
              ),
            ),
            _input(
              _username,
              'Логин',
              Icons.person_outline,
              _field(
                'username',
                V.combine([
                  V.required('Укажите логин'),
                  V.length(min: 3, max: 30),
                  V.pattern(
                    RegExp(r'^[A-Za-z0-9_.-]+$'),
                    'Латинские буквы, цифры, точка, дефис, подчёркивание',
                  ),
                ]),
              ),
            ),
            _input(
              _password,
              'Пароль',
              Icons.lock_outline,
              _field('password', V.strongPassword()),
              obscure: true,
            ),
            // правила пароля с галочками — видно, чего не хватает
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (text, ok) in V.passwordRules)
                    _rule(text, password.isNotEmpty && ok(password)),
                ],
              ),
            ),
            _input(
              _repeat,
              'Повторите пароль',
              Icons.lock_reset,
              (v) => v != _password.text ? 'Пароли не совпадают' : null,
              obscure: true,
              last: true,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.how_to_reg),
              label: const Text('Зарегистрироваться'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => context.go(
                      from == null
                          ? '/login'
                          : '/login?from=${Uri.encodeComponent(from)}',
                    ),
              child: const Text('Уже есть учётная запись? Войти'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon,
    Validator validator, {
    bool obscure = false,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: obscure && !last ? 8 : 16),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        obscureText: obscure && _hidePassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: obscure && !last
              ? IconButton(
                  tooltip: _hidePassword ? 'Показать пароль' : 'Скрыть пароль',
                  icon: Icon(
                    _hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                )
              : null,
        ),
        validator: validator,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onChanged: (_) => _serverErrors.clear(),
        onFieldSubmitted: last ? (_) => _submit() : null,
      ),
    );
  }

  Widget _rule(String text, bool ok) {
    final color = ok ? Colors.green.shade700 : Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
