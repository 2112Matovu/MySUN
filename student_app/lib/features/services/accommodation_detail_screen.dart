import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/phone_launcher.dart';
import 'package:mysun_app/data/models/accommodation_listing.dart';
import 'package:mysun_app/providers/accommodation_providers.dart';
import 'package:mysun_app/widgets/network_image_box.dart';
import 'package:mysun_app/widgets/state_views.dart';

class AccommodationDetailScreen extends ConsumerWidget {
  const AccommodationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accommodationProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Accommodation')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(accommodationProvider(id)),
        ),
        data: (listing) => _Body(listing),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body(this.listing);
  final AccommodationListing listing;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listing = widget.listing;
    final images = listing.imageUrls;

    return ListView(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 240,
              child: images.isEmpty
                  ? const NetworkImageBox(
                      url: null,
                      category: 'Administration',
                      height: 240,
                    )
                  : PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => NetworkImageBox(
                        url: images[i],
                        category: 'Administration',
                        height: 240,
                      ),
                    ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(listing.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text(
                    'UGX ${listing.price}/${listing.type.priceUnit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(child: Text(listing.location)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      listing.isGazetted
                          ? Icons.verified_outlined
                          : Icons.info_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                        listing.isGazetted ? 'Gazetted' : 'Non-gazetted'),
                    backgroundColor:
                        listing.isGazetted ? Colors.green : Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  Chip(
                    avatar: const Icon(Icons.bed_outlined, size: 16),
                    label: Text(listing.roomSharing.label),
                  ),
                  Chip(
                    avatar: Icon(
                      listing.type == AccommodationType.hostel
                          ? Icons.apartment_outlined
                          : Icons.house_outlined,
                      size: 16,
                    ),
                    label: Text(listing.type.label),
                  ),
                  if (!listing.isAvailable)
                    const Chip(
                      label: Text('Currently full'),
                      backgroundColor: Colors.redAccent,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
              if (listing.description != null) ...[
                const Divider(height: 32),
                Text(listing.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
              ],
              if (listing.publisherName != null) ...[
                const SizedBox(height: 16),
                Text('Listed by ${listing.publisherName}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(listing.contactPhone,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  FilledButton.icon(
                    onPressed: () => callNumber(context, listing.contactPhone),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
