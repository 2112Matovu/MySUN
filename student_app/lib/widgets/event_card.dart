import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/providers/bookmarks_provider.dart';
import 'package:mysun_app/widgets/category_badge.dart';
import 'package:mysun_app/widgets/network_image_box.dart';

class EventCard extends ConsumerWidget {
  const EventCard(this.event, {super.key});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(bookmarksProvider).contains(event.bookmarkKey);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NetworkImageBox(
                  url: event.imageUrl,
                  category: event.category,
                  height: 132,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: CategoryBadge(event.category, compact: true),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: _CountdownPill(event: event),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.schedule,
                    text:
                        '${DateFmt.dayLabel(event.dateTime)} • ${DateFmt.time(event.dateTime)}',
                  ),
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.place_outlined, text: event.venue),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'By ${event.organizerName}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => ref
                            .read(bookmarksProvider.notifier)
                            .toggle(event.bookmarkKey),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final label =
        event.isPast ? 'Ended' : 'in ${DateFmt.countdown(event.countdown)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timelapse, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
