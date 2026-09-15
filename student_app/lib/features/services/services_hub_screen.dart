import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/accommodation_listing.dart';
import 'package:mysun_app/providers/accommodation_providers.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/features/transport/transport_screen.dart';
import 'package:mysun_app/widgets/accommodation_card.dart';
import 'package:mysun_app/widgets/state_views.dart';

enum _Service { transport, accommodation }

/// §4.3 Services Hub — extensible services framework (§6). Transport and
/// Accommodation are both live; new services slot in the same way.
final _selectedServiceProvider = StateProvider<_Service>((ref) => _Service.transport);

class ServicesHubScreen extends ConsumerWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedServiceProvider);
    final canPublish = ref.watch(currentUserProvider).role.canPublish;

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: !canPublish
          ? null
          : switch (selected) {
              _Service.transport => FloatingActionButton.extended(
                  onPressed: () => context.push('/publish/new-transport'),
                  icon: const Icon(Icons.add_road_outlined),
                  label: const Text('Add Boda Rider'),
                ),
              _Service.accommodation => FloatingActionButton.extended(
                  onPressed: () => context.push('/publish/new-accommodation'),
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Add Listing'),
                ),
            },
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.directions_bus_outlined, size: 18),
                  label: const Text('Transport'),
                  selected: selected == _Service.transport,
                  onSelected: (_) => ref
                      .read(_selectedServiceProvider.notifier)
                      .state = _Service.transport,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Accommodation'),
                  selected: selected == _Service.accommodation,
                  onSelected: (_) => ref
                      .read(_selectedServiceProvider.notifier)
                      .state = _Service.accommodation,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('More'),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('More services are on the way')),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (selected) {
              _Service.transport => const TransportSection(),
              _Service.accommodation => const _AccommodationSection(),
            },
          ),
        ],
      ),
    );
  }
}

class _AccommodationSection extends ConsumerWidget {
  const _AccommodationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(accommodationTypeFilterProvider);
    final listings = ref.watch(accommodationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(accommodationsProvider);
        await ref.read(accommodationsProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filter == null,
                    onSelected: (_) => ref
                        .read(accommodationTypeFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Hostels'),
                    selected: filter == AccommodationType.hostel,
                    onSelected: (_) => ref
                        .read(accommodationTypeFilterProvider.notifier)
                        .state = AccommodationType.hostel,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Rentals'),
                    selected: filter == AccommodationType.rental,
                    onSelected: (_) => ref
                        .read(accommodationTypeFilterProvider.notifier)
                        .state = AccommodationType.rental,
                  ),
                ],
              ),
            ),
          ),
          listings.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(accommodationsProvider),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.home_outlined,
                    title: 'No listings yet',
                    message: 'Publishers can add hostels and rentals here.',
                  ),
                );
              }
              return SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => AccommodationCard(
                  items[i],
                  onTap: () => context.push('/accommodation/${items[i].id}'),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }
}
