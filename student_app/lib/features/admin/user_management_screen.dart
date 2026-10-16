import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §5.3 User Management — Super Admin only.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          actions: [
            IconButton(
              tooltip: 'Export users as CSV',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: () => _exportCsv(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Publishers'),
              Tab(text: 'Admins'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/grant-access'),
          icon: const Icon(Icons.add),
          label: const Text('Grant Access'),
        ),
        body: const TabBarView(
          children: [
            _UserList(role: UserRole.student),
            _UserList(role: UserRole.publisher),
            _AdminsList(),
          ],
        ),
      ),
    );
  }
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final csv = await ref.read(adminRepositoryProvider).exportUsersCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    messenger.showSnackBar(const SnackBar(
        content: Text('User list copied as CSV. Paste it into a spreadsheet.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't export users: $e")));
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider(role));
    return users.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (items) => items.isEmpty
          ? const EmptyState(icon: Icons.people_outline, title: 'No users')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) => _UserTile(items[i]),
            ),
    );
  }
}

class _AdminsList extends ConsumerWidget {
  const _AdminsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admins = ref.watch(adminUsersProvider(UserRole.admin));
    final minorAdmins = ref.watch(adminUsersProvider(UserRole.minorAdmin));
    if (admins.isLoading || minorAdmins.isLoading) return const LoadingView();
    final items = [...?admins.valueOrNull, ...?minorAdmins.valueOrNull];
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.shield_outlined, title: 'No admins');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) => _UserTile(items[i]),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile(this.user);
  final UserProfile user;

  Future<void> _removeAccess(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove access?'),
        content: Text(
            "${user.name} will lose ${user.role.label} access and become a regular Student."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove Access'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateRole(user.id, UserRole.student);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    ref.invalidate(adminUsersProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('${user.name} is now a Student')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = user.id == ref.watch(currentUserProvider).id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.initials)),
        title: Text(user.name),
        subtitle: Text([
          user.role.label,
          if (user.faculty != null) user.faculty!,
        ].join(' • ')),
        trailing: user.role == UserRole.student || isSelf
            ? null
            : IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove access',
                onPressed: () => _removeAccess(context, ref),
              ),
      ),
    );
  }
}
