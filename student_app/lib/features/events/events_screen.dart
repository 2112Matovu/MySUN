import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/data/repositories/event_repository.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/widgets/category_chips.dart';
import 'package:mysun_app/widgets/event_card.dart';
import 'package:mysun_app/widgets/state_views.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(eventFilterProvider);
    final events = ref.watch(eventsProvider);
    final notifier = ref.read(eventFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search events, venues, organisers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in EventDateFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: filter.dateFilter == f,
                      onSelected: (_) => notifier.setDateFilter(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CategoryChips(
            options: eventCategories,
            selected: filter.category,
            onSelected: notifier.setCategory,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: events.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(eventsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No events match',
                    message: 'Adjust your filters or search.',
                    action: OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.reset();
                      },
                      child: const Text('Clear filters'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(eventsProvider);
                    await ref.read(eventsProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => EventCard(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
