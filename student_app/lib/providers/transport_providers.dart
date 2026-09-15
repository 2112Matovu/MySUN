import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/bus_schedule.dart';
import 'package:mysun_app/data/models/transport_provider.dart';
import 'package:mysun_app/providers/repositories.dart';

/// Search by name or place of service (e.g. a service area) on the
/// Transport screen.
final transportSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Boda-only for now — see [MockData.transportProviders].
final transportProvidersProvider =
    FutureProvider.autoDispose<List<TransportProvider>>((ref) async {
  final repo = ref.watch(transportRepositoryProvider);
  final query = ref.watch(transportSearchQueryProvider).trim();
  return query.isEmpty ? repo.providers() : repo.search(query);
});

final transportProviderProvider =
    FutureProvider.autoDispose.family<TransportProvider, String>((ref, id) async {
  return ref.watch(transportRepositoryProvider).getProvider(id);
});

final busSchedulesProvider =
    FutureProvider.autoDispose<List<BusSchedule>>((ref) async {
  return ref.watch(transportRepositoryProvider).schedules();
});

final nextBusProvider = FutureProvider.autoDispose<BusSchedule?>((ref) async {
  return ref.watch(transportRepositoryProvider).nextBus();
});
