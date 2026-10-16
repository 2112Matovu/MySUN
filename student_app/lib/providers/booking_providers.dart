import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/booking.dart';
import 'package:mysun_app/data/models/campus_service.dart';
import 'package:mysun_app/providers/repositories.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>(
    (ref) => ref.watch(bookingRepositoryProvider).mine());

final incomingBookingsProvider = FutureProvider.autoDispose<List<Booking>>(
    (ref) => ref.watch(bookingRepositoryProvider).incoming());

final serviceCategoryFilterProvider =
    StateProvider.autoDispose<ServiceCategory?>((ref) => null);

final campusServicesProvider =
    FutureProvider.autoDispose<List<CampusService>>((ref) {
  final category = ref.watch(serviceCategoryFilterProvider);
  return ref.watch(campusServiceRepositoryProvider).list(category: category);
});
