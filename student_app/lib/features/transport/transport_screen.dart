import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/core/utils/phone_launcher.dart';
import 'package:mysun_app/features/transport/rate_and_book.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/transport_providers.dart';
import 'package:mysun_app/widgets/state_views.dart';
import 'package:mysun_app/widgets/transport_card.dart';

/// The Transport section of the Services Hub (§4.3). Body-only — the caller
/// (`ServicesHubScreen`) owns the Scaffold/AppBar so multiple services can
/// share one screen.
///
/// Boda-only for now (taxi/bus/matatu removed — see [MockData.transportProviders]).
class TransportSection extends ConsumerWidget {
  const TransportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(transportProvidersProvider);
    final canVerify = ref.watch(currentUserProvider).role.isAdminLevel;

    return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transportProvidersProvider);
          ref.invalidate(nextBusProvider);
          await ref.read(transportProvidersProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _NextBusCard()),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton.icon(
                    onPressed: () => context.push('/bookings'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('My bookings'),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _BodaSearchField()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Text(
                  'Boda riders',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            providers.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingView(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: '$e',
                  onRetry: () => ref.invalidate(transportProvidersProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  final query = ref.watch(transportSearchQueryProvider);
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.no_transfer_outlined,
                      title: query.trim().isEmpty
                          ? 'No boda riders listed yet'
                          : 'No matches for "$query"',
                      message: query.trim().isEmpty
                          ? 'Check back soon.'
                          : 'Try a different name or place.',
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => TransportCard(
                    items[i],
                    onCall: () => callNumber(context, items[i].phoneNumber),
                    onRate: () => showRateDialog(context, ref, items[i]),
                    onBook: () => showBookingSheet(context, ref, items[i]),
                    onToggleVerified: canVerify
                        ? () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(transportRepositoryProvider)
                                  .setVerified(
                                      items[i].id, !items[i].isVerified);
                              ref.invalidate(transportProvidersProvider);
                            } catch (e) {
                              messenger
                                  .showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      );
  }
}

/// Search boda riders by name or place of service (a service area).
class _BodaSearchField extends ConsumerStatefulWidget {
  const _BodaSearchField();

  @override
  ConsumerState<_BodaSearchField> createState() => _BodaSearchFieldState();
}

class _BodaSearchFieldState extends ConsumerState<_BodaSearchField> {
  late final _controller =
      TextEditingController(text: ref.read(transportSearchQueryProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = ref.watch(transportSearchQueryProvider).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search by name or place of service',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(transportSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          isDense: true,
        ),
        onChanged: (v) =>
            ref.read(transportSearchQueryProvider.notifier).state = v,
      ),
    );
  }
}

class _NextBusCard extends ConsumerWidget {
  const _NextBusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nextBus = ref.watch(nextBusProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: nextBus.when(
        loading: () => const SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (e, _) => const SizedBox(
          height: 64,
          child: Center(
            child: Text('Could not load the next bus',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        data: (bus) {
          if (bus == null) {
            return const Text('No buses scheduled',
                style: TextStyle(color: Colors.white));
          }
          final until = bus.nextDeparture().difference(DateTime.now());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Next campus bus',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'in ${DateFmt.countdown(until)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${bus.departureTime}  •  ${bus.routeName}',
                style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${bus.departurePoint}  →  ${bus.destination}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/bus-schedule'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Full schedule'),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
