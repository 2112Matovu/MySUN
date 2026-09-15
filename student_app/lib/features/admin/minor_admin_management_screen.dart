import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §5.3 Minor Admin Management — Super Admin only. Activity figures are
/// illustrative until the audit-log backend exists (§9.5).
class MinorAdminManagementScreen extends ConsumerWidget {
  const MinorAdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minorAdmins = ref.watch(adminUsersProvider(UserRole.minorAdmin));

    return Scaffold(
      appBar: AppBar(title: const Text('Minor Admin Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/admin/grant-access',
          extra: UserRole.minorAdmin,
        ),
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add Minor Admin'),
      ),
      body: minorAdmins.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shield_outlined,
              title: 'No minor admins yet',
              message: 'Appoint one from an existing student or publisher.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active Minor Admins: ${items.length}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (var i = 0; i < items.length; i++) _MinorAdminCard(items[i], i),
            ],
          );
        },
      ),
    );
  }
}

class _MinorAdminCard extends StatelessWidget {
  const _MinorAdminCard(this.user, this.index);
  final UserProfile user;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Deterministic mock activity so the demo looks alive without a backend.
    final actions = 120 + index * 47;
    final performance = actions > 200 ? 'Excellent' : 'Good';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Moderation actions: $actions'),
            Text('Last active: ${(index + 1) * 20} mins ago'),
            Text('Performance: $performance'),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Activity log arrives with the backend')),
                  ),
                  child: const Text('View Activity'),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Fine-grained permissions arrive with the '
                                'backend')),
                  ),
                  child: const Text('Permissions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
