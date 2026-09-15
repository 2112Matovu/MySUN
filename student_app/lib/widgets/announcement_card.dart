import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/providers/bookmarks_provider.dart';
import 'package:mysun_app/widgets/category_badge.dart';
import 'package:mysun_app/widgets/network_image_box.dart';

class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard(this.announcement, {super.key});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(bookmarksProvider).contains(announcement.bookmarkKey);
    final hasImage =
        announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => context.push('/announcement/${announcement.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              NetworkImageBox(
                url: announcement.imageUrl,
                category: announcement.category,
                height: 150,
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryBadge(announcement.category, compact: true),
                      if (announcement.isImportant) ...[
                        const SizedBox(width: 6),
                        _ImportantTag(theme: theme),
                      ],
                      const Spacer(),
                      Text(
                        DateFmt.relative(announcement.publishedAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    announcement.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          announcement.publisherName,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => ref
                            .read(bookmarksProvider.notifier)
                            .toggle(announcement.bookmarkKey),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            saved
                                ? Icons.bookmark
                                : Icons.bookmark_border_outlined,
                            size: 20,
                            color: saved
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportantTag extends StatelessWidget {
  const _ImportantTag({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high,
              size: 12, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 3),
          Text(
            'Important',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
