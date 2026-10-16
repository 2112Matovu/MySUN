import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/core/utils/phone_launcher.dart';
import 'package:mysun_app/data/models/booking.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/booking_providers.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// "My rides" for students, plus a "Requests" tab for publishers and admins
/// who answer bookings for the riders they listed.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider).role;
    final canRespond = role.canPublish || role.isAdminLevel;

    final body = canRespond
        ? const TabBarView(children: [
            _BookingList(incoming: false),
            _BookingList(incoming: true),
          ])
        : const _BookingList(incoming: false);

    return DefaultTabController(
      length: canRespond ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: canRespond
              ? const TabBar(tabs: [Tab(text: 'My rides'), Tab(text: 'Requests')])
              : null,
        ),
        body: body,
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.incoming});
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = incoming ? incomingBookingsProvider : myBookingsProvider;
    final async = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(provider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 80),
              EmptyState(
                icon: Icons.two_wheeler_outlined,
                title: incoming ? 'No ride requests yet' : 'No bookings yet',
                message: incoming
                    ? 'Requests for your riders will show up here.'
                    : 'Book a boda rider from Services > Transport.',
              ),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                _BookingCard(items[i], incoming: incoming),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard(this.booking, {required this.incoming});
  final Booking booking;
  final bool incoming;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _busy = false;

  Future<void> _run(Future<Object?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myBookingsProvider);
      ref.invalidate(incomingBookingsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _statusColor(ThemeData t) => switch (widget.booking.status) {
        BookingStatus.pending => Colors.orange.shade700,
        BookingStatus.accepted => t.colorScheme.primary,
        BookingStatus.completed => Colors.green.shade700,
        BookingStatus.declined || BookingStatus.cancelled => t.colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.booking;
    final repo = ref.read(bookingRepositoryProvider);
    final color = _statusColor(theme);

    final actions = <Widget>[
      if (!widget.incoming && b.status.isActive)
        OutlinedButton(
          onPressed: _busy ? null : () => _run(() => repo.cancel(b.id)),
          child: const Text('Cancel'),
        ),
      if (!widget.incoming &&
          b.status == BookingStatus.accepted &&
          b.providerPhone != null)
        FilledButton.tonalIcon(
          onPressed: () => callNumber(context, b.providerPhone!),
          icon: const Icon(Icons.call, size: 18),
          label: const Text('Call rider'),
        ),
      if (widget.incoming && b.status == BookingStatus.pending) ...[
        OutlinedButton(
          onPressed: _busy ? null : () => _run(() => repo.respond(b.id, 'decline')),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _run(() => repo.respond(b.id, 'accept')),
          child: const Text('Accept'),
        ),
      ],
      if (widget.incoming && b.status == BookingStatus.accepted)
        FilledButton(
          onPressed: _busy ? null : () => _run(() => repo.respond(b.id, 'complete')),
          child: const Text('Mark completed'),
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.incoming
                        ? (b.studentName ?? 'Student')
                        : (b.providerName ?? 'Boda rider'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(b.status.label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${b.pickup}  →  ${b.destination}',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              b.requestedTime == null
                  ? 'As soon as possible'
                  : '${DateFmt.dayLabel(b.requestedTime!)}, ${DateFmt.time(b.requestedTime!)}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            if (widget.incoming && b.providerName != null)
              Text('For: ${b.providerName}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            if (b.note != null) ...[
              const SizedBox(height: 6),
              Text('"${b.note}"',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
