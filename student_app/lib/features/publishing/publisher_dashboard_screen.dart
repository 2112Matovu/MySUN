import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §4.4 Publisher Dashboard — only reachable when [UserRole.canPublish].
class PublisherDashboardScreen extends ConsumerWidget {
  const PublisherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final submissions = ref.watch(publisherSubmissionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Content')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publisherSubmissionsProvider);
          await ref.read(publisherSubmissionsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back, ${user.name}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('Publisher${user.faculty != null ? " — ${user.faculty}" : ""}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 20),
            Text('RECENT SUBMISSIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 8),
            submissions.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingView(),
              ),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(publisherSubmissionsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No submissions yet.'),
                  );
                }
                return Column(
                  children: [
                    for (final s in items) _SubmissionTile(s),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text('QUICK ACTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.campaign_outlined,
              label: 'New Announcement',
              onTap: () => context.push('/publish/new-announcement'),
            ),
            _QuickAction(
              icon: Icons.event_outlined,
              label: 'New Event',
              onTap: () => context.push('/publish/new-event'),
            ),
            _QuickAction(
              icon: Icons.add_home_outlined,
              label: 'New Accommodation Listing',
              onTap: () => context.push('/publish/new-accommodation'),
            ),
            _QuickAction(
              icon: Icons.add_road_outlined,
              label: 'New Boda Rider',
              onTap: () => context.push('/publish/new-transport'),
            ),
            _QuickAction(
              icon: Icons.drafts_outlined,
              label: 'View Drafts',
              trailing: submissions.maybeWhen(
                data: (items) => items
                    .where((s) => s.status == SubmissionStatus.draft)
                    .length
                    .toString(),
                orElse: () => null,
              ),
              onTap: () => context.push('/publish/drafts'),
            ),
            _QuickAction(
              icon: Icons.bar_chart_outlined,
              label: 'My Performance',
              onTap: () => context.push('/publish/performance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends ConsumerWidget {
  const _SubmissionTile(this.submission);
  final PublisherSubmission submission;

  static const _routeByType = {
    SubmissionType.announcement: '/publish/new-announcement',
    SubmissionType.event: '/publish/new-event',
    SubmissionType.accommodation: '/publish/new-accommodation',
    SubmissionType.transport: '/publish/new-transport',
  };

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this listing?'),
        content: Text(
            '"${submission.title}" will be taken down immediately. This '
            "can't be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await removeMyContent(ref, submission);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDraft = submission.status == SubmissionStatus.draft;
    // A publisher can take down their own live boda listing (§4.4-style
    // self-service, separate from admin moderation).
    final canRemove = submission.status == SubmissionStatus.published &&
        submission.type == SubmissionType.transport;
    final (icon, color, label) = switch (submission.status) {
      SubmissionStatus.published => (Icons.check_circle, Colors.green, 'Live'),
      SubmissionStatus.removed => (Icons.cancel, Colors.red, 'Removed'),
      SubmissionStatus.draft => (Icons.edit_note, Colors.grey, 'Draft'),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(submission.title),
        subtitle: Text(
          submission.status == SubmissionStatus.removed &&
                  submission.removalReason != null
              ? submission.removalReason!
              : '$label • ${DateFmt.relative(submission.updatedAt)}',
        ),
        trailing: switch ((isDraft, canRemove)) {
          (true, _) => const Icon(Icons.chevron_right),
          (_, true) => IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmRemove(context, ref),
            ),
          _ => null,
        },
        onTap: isDraft
            ? () => context.push(_routeByType[submission.type]!,
                extra: submission)
            : null,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: trailing != null
            ? Text(trailing!)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
