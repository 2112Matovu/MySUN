import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/providers/announcements_provider.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/providers/notifications_provider.dart';
import 'package:mysun_app/providers/transport_providers.dart';
import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/widgets/announcement_card.dart';
import 'package:mysun_app/widgets/event_card.dart';
import 'package:mysun_app/widgets/category_chips.dart';
import 'package:mysun_app/widgets/state_views.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final category = ref.watch(announcementCategoryProvider);
    final showAll = category == 'All';
    final announcements = ref.watch(announcementsProvider);
    final feed = ref.watch(campusFeedProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(announcementsProvider);
          ref.invalidate(campusFeedProvider);
          ref.invalidate(nextEventProvider);
          ref.invalidate(nextBusProvider);
          await ref.read(
              (showAll ? campusFeedProvider : announcementsProvider).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_greeting()},',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  Text(user.name.split(' ').first,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final unread = ref.watch(unreadCountProvider);
                    return IconButton(
                      tooltip: 'Notifications',
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      onPressed: () => context.push('/notifications'),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _QuickStatusRow()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Text('Campus feed',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryChips(
                options: announcementCategories,
                selected: category,
                onSelected: (c) =>
                    ref.read(announcementCategoryProvider.notifier).state = c,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (showAll)
              feed.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: '$e',
                    onRetry: () => ref.invalidate(campusFeedProvider),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'Nothing on the feed yet',
                        message: 'New announcements and events show up here.',
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return item is Event
                          ? EventCard(item)
                          : AnnouncementCard(item as Announcement);
                    },
                  );
                },
              )
            else
              announcements.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: '$e',
                    onRetry: () => ref.invalidate(announcementsProvider),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'No announcements here',
                        message: 'Try another category.',
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => AnnouncementCard(items[i]),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _QuickStatusRow extends ConsumerWidget {
  const _QuickStatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextEvent = ref.watch(nextEventProvider);
    final nextBus = ref.watch(nextBusProvider);
    final unread = ref.watch(unreadCountProvider);

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatusCard(
            icon: Icons.event_available_outlined,
            label: 'Next event',
            value: nextEvent.maybeWhen(
              data: (e) => e == null ? 'Nothing soon' : e.title,
              orElse: () => '…',
            ),
            sub: nextEvent.maybeWhen(
              data: (e) => e == null ? '' : DateFmt.countdown(e.countdown),
              orElse: () => '',
            ),
            onTap: () => context.push('/events'),
          ),
          _StatusCard(
            icon: Icons.directions_bus_outlined,
            label: 'Next bus',
            value: nextBus.maybeWhen(
              data: (b) => b == null ? 'No bus' : b.departureTime,
              orElse: () => '…',
            ),
            sub: nextBus.maybeWhen(
              data: (b) => b == null ? '' : b.destination,
              orElse: () => '',
            ),
            onTap: () => context.push('/bus-schedule'),
          ),
          _StatusCard(
            icon: Icons.notifications_none,
            label: 'Alerts',
            value: unread == 0 ? 'All caught up' : '$unread unread',
            sub: unread == 0 ? '' : 'Tap to review',
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
