import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/providers/announcements_provider.dart';
import 'package:mysun_app/providers/bookmarks_provider.dart';
import 'package:mysun_app/widgets/category_badge.dart';
import 'package:mysun_app/widgets/network_image_box.dart';
import 'package:mysun_app/widgets/state_views.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(announcementProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          async.maybeWhen(
            data: (a) {
              final saved =
                  ref.watch(bookmarksProvider).contains(a.bookmarkKey);
              return IconButton(
                tooltip: 'Bookmark',
                icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border_outlined),
                onPressed: () => ref
                    .read(bookmarksProvider.notifier)
                    .toggle(a.bookmarkKey),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sharing isn't available yet.")),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(announcementProvider(id)),
        ),
        data: (a) => ListView(
          children: [
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
              NetworkImageBox(
                url: a.imageUrl,
                category: a.category,
                height: 210,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryBadge(a.category),
                      if (a.isImportant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Important',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    a.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(a.publisherName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule,
                          size: 15, color: theme.colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(DateFmt.full(a.publishedAt),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    a.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                  if (a.expiresAt != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 8),
                          Text('Valid until ${DateFmt.full(a.expiresAt!)}',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
