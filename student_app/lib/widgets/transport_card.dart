import 'package:flutter/material.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/data/models/transport_provider.dart';

class TransportCard extends StatelessWidget {
  const TransportCard(this.provider, {super.key, this.onCall, this.onTap});

  final TransportProvider provider;
  final VoidCallback? onCall;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(serviceTypeIcon(provider.serviceType),
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                provider.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified,
                                  size: 15, color: theme.colorScheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 15, color: Colors.amber.shade600),
                            const SizedBox(width: 3),
                            Text(
                              '${provider.rating.toStringAsFixed(1)} '
                              '(${provider.ratingCount})',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.serviceType[0].toUpperCase() +
                                  provider.serviceType.substring(1),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (provider.operatingHours != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      provider.operatingHours!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
              if (provider.serviceAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final area in provider.serviceAreas.take(4))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(area,
                            style: theme.textTheme.labelSmall),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.phoneNumber,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
