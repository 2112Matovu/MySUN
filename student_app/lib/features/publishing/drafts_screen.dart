import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §4.4 "View Drafts" — resume editing or discard a saved draft.
class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  static const _routeByType = {
    SubmissionType.announcement: '/publish/new-announcement',
    SubmissionType.event: '/publish/new-event',
    SubmissionType.accommodation: '/publish/new-accommodation',
    SubmissionType.transport: '/publish/new-transport',
  };

  static const _labelByType = {
    SubmissionType.announcement: 'Announcement',
    SubmissionType.event: 'Event',
    SubmissionType.accommodation: 'Accommodation listing',
    SubmissionType.transport: 'Boda rider',
  };

  static const _iconByType = {
    SubmissionType.announcement: Icons.campaign_outlined,
    SubmissionType.event: Icons.event_outlined,
    SubmissionType.accommodation: Icons.add_home_outlined,
    SubmissionType.transport: Icons.add_road_outlined,
  };

  Future<void> _discard(
      BuildContext context, WidgetRef ref, PublisherSubmission draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this draft?'),
        content: Text('"${draft.title}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(publisherRepositoryProvider).discardDraft(draft.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    ref.invalidate(publisherDraftsProvider);
    ref.invalidate(publisherSubmissionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(publisherDraftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Drafts')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(publisherDraftsProvider),
        child: drafts.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(publisherDraftsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.drafts_outlined,
                title: 'No drafts',
                message: 'Anything you save as a draft shows up here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final draft = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(_iconByType[draft.type]),
                    title: Text(draft.title.isEmpty ? '(Untitled)' : draft.title),
                    subtitle: Text(
                        '${_labelByType[draft.type]} • saved ${DateFmt.relative(draft.updatedAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _discard(context, ref, draft),
                    ),
                    onTap: () =>
                        context.push(_routeByType[draft.type]!, extra: draft),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
