import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/repositories/search_repository.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

final _queryProvider = StateProvider.autoDispose<String>((ref) => '');

final _searchProvider = FutureProvider.autoDispose<SearchResults>((ref) async {
  final q = ref.watch(_queryProvider).trim();
  if (q.length < 2) return const SearchResults();
  // Wait briefly so a result isn't fetched for every keystroke; a newer
  // keystroke disposes this provider run before the request is sent.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (cancelled) return const SearchResults();
  return ref.read(searchRepositoryProvider).search(q);
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
              title: 'Search announcements, events, housing & transport',
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
                    _GroupHeader('Accommodation', r.accommodation.length),
                    for (final l in r.accommodation)
                      ListTile(
                        leading: const Icon(Icons.home_work_outlined),
                        title: Text(l.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${l.type.label} • ${l.location}',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => context.push('/accommodation/${l.id}'),
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
