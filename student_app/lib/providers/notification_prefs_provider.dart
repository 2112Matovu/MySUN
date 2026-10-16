import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/notification_prefs.dart';
import 'package:mysun_app/providers/repositories.dart';

/// The user's notification category choices, saved on the server so they
/// apply to push as well as the in-app list.
class NotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() =>
      ref.watch(notificationRepositoryProvider).getPreferences();

  /// Optimistic: flips the switch immediately and rolls back if the save fails.
  /// Returns an error message on failure, else null.
  Future<String?> set(NotificationCategory category, bool value) async {
    final before = state.valueOrNull;
    if (before == null) return 'Settings are still loading';
    final next = before.toggled(category, value);
    state = AsyncData(next);
    try {
      await ref.read(notificationRepositoryProvider).setPreferences(next);
      return null;
    } catch (e) {
      state = AsyncData(before);
      return '$e';
    }
  }
}

final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
        NotificationPrefsNotifier.new);
