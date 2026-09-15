import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/accommodation_listing.dart';
import 'package:mysun_app/providers/repositories.dart';

/// Selected type filter chip in the Accommodation section ("All" by default).
final accommodationTypeFilterProvider = StateProvider<AccommodationType?>(
  (ref) => null,
);

final accommodationsProvider =
    FutureProvider.autoDispose<List<AccommodationListing>>((ref) async {
  final repo = ref.watch(accommodationRepositoryProvider);
  final type = ref.watch(accommodationTypeFilterProvider);
  return repo.list(type: type);
});

final accommodationProvider =
    FutureProvider.autoDispose.family<AccommodationListing, String>(
        (ref, id) async {
  return ref.watch(accommodationRepositoryProvider).getById(id);
});
