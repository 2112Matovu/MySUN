import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/app_notification.dart';
import 'package:mysun_app/providers/notifications_provider.dart';
import 'package:mysun_app/widgets/notification_tile.dart';
import 'package:mysun_app/widgets/state_views.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, AppNotification n) {
    switch (n.type) {
      case 'announcement':
        if (n.relatedId != null) context.push('/announcement/${n.relatedId}');
      case 'event':
      case 'reminder':
        if (n.relatedId != null) context.push('/event/${n.relatedId}');
      case 'transport':
        context.push('/bus-schedule');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          async.maybeWhen(
            data: (items) => items.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: notifier.markAllRead,
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: notifier.refresh,
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message: 'Alerts about announcements, events and buses land here.',
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                return NotificationTile(
                  n,
                  onTap: () {
                    notifier.markRead(n.id);
                    _open(context, n);
                  },
                  onDismiss: () => notifier.dismiss(n.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
