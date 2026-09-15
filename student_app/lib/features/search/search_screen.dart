import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/data/models/transport_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

final _queryProvider = StateProvider.autoDispose<String>((ref) => '');

class _Results {
  const _Results(this.announcements, this.events, this.transport);
  final List<Announcement> announcements;
  final List<Event> events;
  final List<TransportProvider> transport;

  bool get isEmpty =>
      announcements.isEmpty && events.isEmpty && transport.isEmpty;
  int get total => announcements.length + events.length + transport.length;
}

final _searchProvider = FutureProvider.autoDispose<_Results>((ref) async {
  final q = ref.watch(_queryProvider).trim();
  if (q.length < 2) return const _Results([], [], []);

  final announcements =
      await ref.watch(announcementRepositoryProvider).search(q);
  final events = await ref.watch(eventRepositoryProvider).search(q);
  final transport = await ref.watch(transportRepositoryProvider).search(q);

  return _Results(announcements, events, transport);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_queryProvider);
    final results = ref.watch(_searchProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => ref.read(_queryProvider.notifier).state = v,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search MySun',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      ref.read(_queryProvider.notifier).state = '';
                    },
                  ),
          ),
        ),
      ),
      body: query.trim().length < 2
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search announcements, events & transport',
              message: 'Type at least two characters.',
            )
          : results.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (r) {
                if (r.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No results for "${query.trim()}"',
                    message: 'Try a different word.',
                  );
                }
                return ListView(
                  children: [
                    _GroupHeader('Announcements', r.announcements.length),
                    for (final a in r.announcements)
                      ListTile(
                        leading: Icon(categoryIcon(a.category),
                            color: categoryColor(a.category)),
                        title: Text(a.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${a.category} • ${DateFmt.relative(a.publishedAt)}'),
                        onTap: () => context.push('/announcement/${a.id}'),
                      ),
                    _GroupHeader('Events', r.events.length),
                    for (final e in r.events)
                      ListTile(
                        leading: Icon(categoryIcon(e.category),
                            color: categoryColor(e.category)),
                        title: Text(e.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${DateFmt.dayLabel(e.dateTime)} • ${e.venue}',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => context.push('/event/${e.id}'),
                      ),
                    _GroupHeader('Transport', r.transport.length),
                    for (final t in r.transport)
                      ListTile(
                        leading: Icon(serviceTypeIcon(t.serviceType)),
                        title: Text(t.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(t.phoneNumber),
                        onTap: () => context.go('/services'),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        '$label ($count)',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
