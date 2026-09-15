import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/bus_schedule.dart';
import 'package:mysun_app/providers/transport_providers.dart';
import 'package:mysun_app/widgets/bus_schedule_tile.dart';
import 'package:mysun_app/widgets/state_views.dart';

class BusScheduleScreen extends ConsumerStatefulWidget {
  const BusScheduleScreen({super.key});

  @override
  ConsumerState<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends ConsumerState<BusScheduleScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(busSchedulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bus schedule')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search routes or destinations',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: schedules.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(busSchedulesProvider),
              ),
              data: (all) {
                final items = _query.isEmpty
                    ? all
                    : all
                        .where((b) =>
                            b.routeName.toLowerCase().contains(_query) ||
                            b.destination.toLowerCase().contains(_query) ||
                            b.departurePoint.toLowerCase().contains(_query))
                        .toList();
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.schedule,
                    title: 'No matching departures',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(busSchedulesProvider);
                    await ref.read(busSchedulesProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    children: [
                      _SectionLabel('Upcoming today & tomorrow (${items.length})'),
                      for (final BusSchedule s in items) BusScheduleTile(s),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
