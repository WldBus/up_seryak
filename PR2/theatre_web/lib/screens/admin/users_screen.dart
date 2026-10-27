import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/admin_notifier.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/debounced_field.dart';
import '../../widgets/feedback.dart';

/// «Пользователи» — экран только для администратора: учётные записи и роли.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminNotifier>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminNotifier>();
    final me = context.watch<AuthNotifier>().user;
    final users = admin.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи и роли')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: 360,
            child: DebouncedField(
              value: _search,
              label: 'Поиск по логину, имени, почте',
              icon: Icons.search,
              onChanged: (v) {
                _search = v;
                admin.loadUsers(search: v);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (admin.error != null)
            ListTile(
              leading: const Icon(Icons.cloud_off),
              title: Text(admin.error!),
              trailing: TextButton(
                onPressed: () => admin.loadUsers(search: _search),
                child: const Text('Повторить'),
              ),
            )
          else if (users == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final u in users)
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(u.fullName.isEmpty ? '?' : u.fullName[0]),
                      ),
                      title: Text(
                        u.id == me?.id ? '${u.fullName} (это вы)' : u.fullName,
                      ),
                      subtitle: Text('${u.username} · ${u.email}'),
                      trailing: DropdownButton<Role>(
                        value: u.role,
                        // свою роль сменить нельзя — иначе можно остаться
                        // без администратора. сервер тоже не даст (409)
                        onChanged: u.id == me?.id
                            ? null
                            : (role) {
                                if (role == null || role == u.role) return;
                                runWithFeedback(
                                  context,
                                  '${u.fullName}: роль «${role.label}»',
                                  () => admin.setRole(u, role),
                                );
                              },
                        items: [
                          for (final r in Role.values)
                            DropdownMenuItem(value: r, child: Text(r.label)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Новая роль начнёт действовать, когда у пользователя обновится '
            'токен (не позже чем через срок жизни токена доступа).',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
