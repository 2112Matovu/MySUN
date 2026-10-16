import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/repositories/admin_repository.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

const _actionLabels = {
  'role_change': 'Role changed',
  'content_removed': 'Content removed',
  'verify_toggle': 'Rider verification changed',
  'users_exported': 'Users exported',
  'account_deleted': 'Account deleted',
};

/// FR-ADM-05: who did what, newest first. Super Admin only.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(auditLogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: log.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: '$e', onRetry: () => ref.invalidate(auditLogProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Nothing logged yet',
              message: 'Role changes, removals and exports will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(auditLogProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _AuditTile(items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile(this.entry);
  final AuditEntry entry;

  String get _detail {
    final d = entry.detail;
    switch (entry.action) {
      case 'role_change':
        return '${d['name'] ?? entry.targetId}: ${d['from']} -> ${d['to']}';
      case 'content_removed':
        return '"${d['title'] ?? ''}" - ${d['reason'] ?? ''}';
      case 'verify_toggle':
        return d['is_verified'] == true ? 'Marked verified' : 'Verification removed';
      case 'users_exported':
        return '${d['count']} users';
      default:
        return d.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = entry.createdAt;
    final when =
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return ListTile(
      title: Text(_actionLabels[entry.action] ?? entry.action),
      subtitle: Text('$_detail\nby ${entry.actorName ?? 'unknown'}'),
      isThreeLine: true,
      trailing: Text(when, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
