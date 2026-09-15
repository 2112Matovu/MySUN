import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §5.3 Main Dashboard — landing screen of the Admin tab. Same visibility
/// rule as Publishing: an extra tab inside the one mobile app, gated by role
/// (§4.5-style access control, applied to admin/minor-admin here).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user.role == UserRole.admin;
    final analytics = ref.watch(adminAnalyticsProvider);
    final queue = ref.watch(moderationQueueProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MySun Admin')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminAnalyticsProvider);
          ref.invalidate(moderationQueueProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(user.name,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(user.role.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 20),
            const _SectionLabel('SYSTEM HEALTH'),
            const SizedBox(height: 8),
            analytics.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (a) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _StatusRow(
                        label: 'API Status',
                        value: a.apiOnline ? 'Online' : 'Offline',
                        ok: a.apiOnline,
                      ),
                      _StatusRow(
                        label: 'Database',
                        value: '${a.databaseHealthPercent}%',
                        ok: a.databaseHealthPercent > 90,
                      ),
                      _StatusRow(
                        label: 'Storage',
                        value: '${a.storageUsedPercent.toStringAsFixed(0)}% used',
                        ok: a.storageUsedPercent < 85,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(isSuperAdmin ? 'KEY METRICS (Last 7 days)' : 'MODERATION'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (isSuperAdmin)
                    analytics.maybeWhen(
                      data: (a) => ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: const Text('Daily active users'),
                        trailing: Text('${a.dailyActiveUsers}'),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  if (isSuperAdmin)
                    analytics.maybeWhen(
                      data: (a) => ListTile(
                        leading: const Icon(Icons.edit_note_outlined),
                        title: const Text('Active publishers'),
                        trailing: Text('${a.publisherCount}'),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  queue.maybeWhen(
                    data: (items) => ListTile(
                      leading: const Icon(Icons.gavel_outlined),
                      title: const Text('Live content to review'),
                      trailing: Text('${items.length} items'),
                      onTap: () => context.push('/admin/moderation'),
                    ),
                    orElse: () => const ListTile(
                      leading: Icon(Icons.gavel_outlined),
                      title: Text('Live content to review'),
                      trailing: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('MANAGE'),
            const SizedBox(height: 8),
            _AdminLink(
              icon: Icons.gavel_outlined,
              label: 'Moderation Queue',
              onTap: () => context.push('/admin/moderation'),
            ),
            if (isSuperAdmin) ...[
              _AdminLink(
                icon: Icons.manage_accounts_outlined,
                label: 'User Management',
                onTap: () => context.push('/admin/users'),
              ),
              _AdminLink(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                onTap: () => context.push('/admin/analytics'),
              ),
              _AdminLink(
                icon: Icons.shield_outlined,
                label: 'Minor Admins',
                onTap: () => context.push('/admin/minor-admins'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6));
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value, required this.ok});
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error,
              size: 16, color: ok ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AdminLink extends StatelessWidget {
  const _AdminLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
