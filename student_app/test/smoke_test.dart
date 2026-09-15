import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/app.dart';
import 'package:mysun_app/data/repositories/accommodation_repository.dart';
import 'package:mysun_app/data/repositories/admin_repository.dart';
import 'package:mysun_app/data/repositories/announcement_repository.dart';
import 'package:mysun_app/data/repositories/auth_repository.dart';
import 'package:mysun_app/data/repositories/event_repository.dart';
import 'package:mysun_app/data/repositories/notification_repository.dart';
import 'package:mysun_app/data/repositories/publisher_repository.dart';
import 'package:mysun_app/data/repositories/transport_repository.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/settings_provider.dart';

/// The app defaults to the real HTTP backend (see `providers/repositories.dart`)
/// — this test overrides every repository with its `Mock*` counterpart so it
/// stays hermetic and network-free, exercising the same demo-account flow the
/// mocks were built for.
final _mockOverrides = [
  authRepositoryProvider.overrideWithValue(MockAuthRepository()),
  announcementRepositoryProvider.overrideWithValue(MockAnnouncementRepository()),
  eventRepositoryProvider.overrideWithValue(MockEventRepository()),
  accommodationRepositoryProvider.overrideWithValue(MockAccommodationRepository()),
  transportRepositoryProvider.overrideWithValue(MockTransportRepository()),
  notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
  adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
  publisherRepositoryProvider.overrideWithValue(MockPublisherRepository()),
];

void main() {
  testWidgets('app boots to login, then reaches the feed after sign-in',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ..._mockOverrides,
        ],
        child: const MySunApp(),
      ),
    );

    // Splash shows the brand name immediately.
    expect(find.text('MySun'), findsOneWidget);

    // Let the splash timer elapse; an unauthenticated session lands on Login.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sign In'), findsOneWidget);

    // Sign in with the demo student account (see MockAuthRepository).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'student@mysun.ug');
    await tester.enterText(fields.at(1), 'student123');
    await tester.tap(find.text('Sign In'));

    // Let the mock login latency and the resulting redirect settle, then the
    // home feed's own mock fetch.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Campus feed'), findsOneWidget);
  });
}
