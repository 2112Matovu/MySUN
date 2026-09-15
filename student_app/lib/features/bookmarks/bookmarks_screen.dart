import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/providers/bookmarks_provider.dart';
import 'package:mysun_app/widgets/announcement_card.dart';
import 'package:mysun_app/widgets/event_card.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// §4.3 Bookmarks (renamed from "Saved" in the earlier spec).
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(bookmarkedAnnouncementsProvider);
    final events = ref.watch(bookmarkedEventsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'News'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            announcements.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.bookmark_border,
                      title: 'No saved announcements',
                      message: 'Tap the bookmark on any announcement to keep it '
                          'here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      itemCount: items.length,
                      itemBuilder: (context, i) => AnnouncementCard(items[i]),
                    ),
            ),
            events.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.bookmark_border,
                      title: 'No saved events',
                      message: 'Bookmark an event and it shows up here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      itemCount: items.length,
                      itemBuilder: (context, i) => EventCard(items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
