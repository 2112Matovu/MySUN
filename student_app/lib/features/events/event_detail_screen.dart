import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/providers/bookmarks_provider.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/widgets/category_badge.dart';
import 'package:mysun_app/widgets/network_image_box.dart';
import 'package:mysun_app/widgets/state_views.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _reminderSet = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(eventProvider(widget.id));

    return Scaffold(
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(eventProvider(widget.id)),
        ),
        data: (event) {
          final saved =
              ref.watch(bookmarksProvider).contains(event.bookmarkKey);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(saved
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined),
                    onPressed: () => ref
                        .read(bookmarksProvider.notifier)
                        .toggle(event.bookmarkKey),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: NetworkImageBox(
                    url: event.imageUrl,
                    category: event.category,
                    height: 240,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CategoryBadge(event.category),
                          const Spacer(),
                          if (!event.isPast)
                            _CountdownChip(countdown: event.countdown),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        event.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800, height: 1.2),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        title: DateFmt.dayLabel(event.dateTime),
                        subtitle: DateFmt.full(event.dateTime),
                      ),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        title: event.venue,
                        subtitle: 'Venue',
                      ),
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        title: event.organizerName,
                        subtitle: 'Organiser',
                      ),
                      if (event.capacity != null) ...[
                        const SizedBox(height: 8),
                        _CapacityBar(
                          registered: event.registeredCount,
                          capacity: event.capacity!,
                        ),
                      ],
                      const Divider(height: 32),
                      Text('About this event',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(event.description,
                          style:
                              theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Map preview will appear here once location '
                                'services are wired in.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: async.maybeWhen(
        data: (event) => _ActionBar(
          event: event,
          reminderSet: _reminderSet,
          onReminderToggle: () {
            setState(() => _reminderSet = !_reminderSet);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_reminderSet
                    ? 'Reminder set for ${DateFmt.dayLabel(event.dateTime)}'
                    : 'Reminder removed'),
              ),
            );
          },
          onAddToCalendar: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Calendar export isn't available yet.")),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.registered, required this.capacity});

  final int registered;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = capacity == 0 ? 0.0 : (registered / capacity).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$registered registered',
                style: theme.textTheme.labelMedium),
            Text('$capacity capacity',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.countdown});
  final Duration countdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timelapse,
              size: 14, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 5),
          Text(
            'in ${DateFmt.countdown(countdown)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.event,
    required this.reminderSet,
    required this.onReminderToggle,
    required this.onAddToCalendar,
  });

  final Event event;
  final bool reminderSet;
  final VoidCallback onReminderToggle;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: event.isPast ? null : onReminderToggle,
              icon: Icon(reminderSet
                  ? Icons.notifications_active
                  : Icons.notifications_none),
              label: Text(reminderSet ? 'Reminder on' : 'Remind me'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onAddToCalendar,
              icon: const Icon(Icons.calendar_month),
              label: const Text('Add to calendar'),
            ),
          ),
        ],
      ),
    );
  }
}
