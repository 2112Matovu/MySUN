import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §5.3 "Grant Publisher Access" — Super Admin only. Also used from the
/// Minor Admin management screen to appoint a new minor admin (§7.3 Role
/// Assignment: Super Admin only).
class GrantRoleScreen extends ConsumerStatefulWidget {
  const GrantRoleScreen({super.key, this.presetRole});

  /// When set (e.g. from "+ Add More Minor Admins"), the role picker is
  /// preselected and the user only needs to pick a person.
  final UserRole? presetRole;

  @override
  ConsumerState<GrantRoleScreen> createState() => _GrantRoleScreenState();
}

class _GrantRoleScreenState extends ConsumerState<GrantRoleScreen> {
  final _search = TextEditingController();
  UserProfile? _selected;
  late UserRole _newRole = widget.presetRole ?? UserRole.publisher;
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _grant() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateRole(selected.id, _newRole);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    ref.invalidate(adminUsersProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${selected.name} is now ${_newRole.label}'),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(adminUsersProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Grant Access')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search user...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          directory.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(message: '$e'),
            data: (users) {
              final query = _search.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? users
                  : users
                      .where((u) => u.name.toLowerCase().contains(query))
                      .toList();
              return RadioGroup<UserProfile>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
                child: Column(
                  children: [
                    for (final u in filtered)
                      RadioListTile<UserProfile>(
                        value: u,
                        title: Text(u.name),
                        subtitle: Text('${u.role.label} • ${u.email}'),
                      ),
                  ],
                ),
              );
            },
          ),
          if (_selected != null) ...[
            const Divider(height: 32),
            Text('Selected: ${_selected!.name}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Current role: ${_selected!.role.label}'),
            const SizedBox(height: 16),
            Text('New Role:', style: Theme.of(context).textTheme.labelLarge),
            RadioGroup<UserRole>(
              groupValue: _newRole,
              onChanged: (v) {
                if (v != null) setState(() => _newRole = v);
              },
              child: Column(
                children: [
                  for (final r in [
                    UserRole.publisher,
                    UserRole.minorAdmin,
                    UserRole.admin,
                  ])
                    RadioListTile<UserRole>(value: r, title: Text(r.label)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _grant,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Grant Access'),
            ),
          ],
        ],
      ),
    );
  }
}
