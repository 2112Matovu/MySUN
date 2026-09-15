import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §5.3 Moderation Queue, adapted: publishing is immediate (no pre-approval
/// gate — see [PublisherRepository]), so this is a review-and-remove list,
/// not an approve/reject queue. Open to both Super Admin and Minor Admin.
class ModerationQueueScreen extends ConsumerWidget {
  const ModerationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(moderationQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Content Review')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(moderationQueueProvider),
        child: queue.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(moderationQueueProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.task_alt,
                title: 'Nothing to review',
                message: 'No content is currently live from publishers.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Everything below is already live. Remove anything that '
                  "doesn't align with the terms and conditions.",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 12),
                for (final item in items) _QueueTile(item),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile(this.submission);
  final PublisherSubmission submission;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this content?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "This takes it down immediately. State why it doesn't align "
                'with the terms and conditions.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    try {
      await removeSubmission(ref, submission, reason: reason);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    ref.invalidate(moderationQueueProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeLabel = switch (submission.type) {
      SubmissionType.announcement => 'Announcement',
      SubmissionType.event => 'Event',
      SubmissionType.accommodation => 'Accommodation listing',
      SubmissionType.transport => 'Boda rider',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(typeLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(submission.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('By: ${submission.publisherName}'),
            Text('Live • ${DateFmt.relative(submission.updatedAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _remove(context, ref),
                icon: Icon(Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error),
                label: Text('Reject (Remove)',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
