import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/network/api_client.dart';
import 'package:mysun_app/core/network/token_storage.dart';
import 'package:mysun_app/data/repositories/accommodation_repository.dart';
import 'package:mysun_app/data/repositories/admin_repository.dart';
import 'package:mysun_app/data/repositories/announcement_repository.dart';
import 'package:mysun_app/data/repositories/auth_repository.dart';
import 'package:mysun_app/data/repositories/booking_repository.dart';
import 'package:mysun_app/data/repositories/campus_service_repository.dart';
import 'package:mysun_app/data/repositories/event_repository.dart';
import 'package:mysun_app/data/repositories/notification_repository.dart';
import 'package:mysun_app/data/repositories/publisher_repository.dart';
import 'package:mysun_app/data/repositories/search_repository.dart';
import 'package:mysun_app/data/repositories/transport_repository.dart';

/// Repository wiring — talks to the real FastAPI backend (`backend/`, see
/// `AppConstants.apiBaseUrl`). Swap any of these back to the matching
/// `Mock*Repository` to run the app fully offline against seed data.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => HttpAnnouncementRepository(ref.watch(dioProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => HttpEventRepository(ref.watch(dioProvider)),
);

final accommodationRepositoryProvider = Provider<AccommodationRepository>(
  (ref) => HttpAccommodationRepository(ref.watch(dioProvider)),
);

final transportRepositoryProvider = Provider<TransportRepository>(
  (ref) => HttpTransportRepository(ref.watch(dioProvider)),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => HttpSearchRepository(ref.watch(dioProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => HttpNotificationRepository(ref.watch(dioProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => HttpAdminRepository(ref.watch(dioProvider)),
);

final publisherRepositoryProvider = Provider<PublisherRepository>(
  (ref) => HttpPublisherRepository(ref.watch(dioProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => HttpBookingRepository(ref.watch(dioProvider)),
);

final campusServiceRepositoryProvider = Provider<CampusServiceRepository>(
  (ref) => HttpCampusServiceRepository(ref.watch(dioProvider)),
);
