import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/app_notification.dart';
import 'package:mysun_app/providers/repositories.dart';

/// The notification centre. Read from the repository, then mutated locally
/// (mark read / dismiss) until the backend PATCH/DELETE endpoints exist.
class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    return ref.watch(notificationRepositoryProvider).list();
  }

  List<AppNotification> get _current => state.valueOrNull ?? const [];

  void markRead(String id) {
    state = AsyncData([
      for (final n in _current)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
    // Best-effort — the optimistic update above already reflects it.
    ref.read(notificationRepositoryProvider).markRead(id).catchError((_) {});
  }

  void markAllRead() {
    final unreadIds = _current.where((n) => !n.isRead).map((n) => n.id);
    state = AsyncData([
      for (final n in _current) n.copyWith(isRead: true),
    ]);
    for (final id in unreadIds) {
      ref.read(notificationRepositoryProvider).markRead(id).catchError((_) {});
    }
  }

  void dismiss(String id) {
    state = AsyncData(_current.where((n) => n.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).list(),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.isRead).length;
});
