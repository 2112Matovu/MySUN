import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

const _typeLabels = {
  SubmissionType.announcement: 'Announcements',
  SubmissionType.event: 'Events',
  SubmissionType.accommodation: 'Accommodation listings',
  SubmissionType.transport: 'Boda riders',
};

const _typeIcons = {
  SubmissionType.announcement: Icons.campaign_outlined,
  SubmissionType.event: Icons.event_outlined,
  SubmissionType.accommodation: Icons.add_home_outlined,
  SubmissionType.transport: Icons.add_road_outlined,
};

/// §1.4 "Performance metrics and analytics" — a publisher's own activity.
/// Counts are real (derived from submission history); views/engagement are
/// illustrative until the backend analytics pipeline exists (§9.6).
class MyPerformanceScreen extends ConsumerWidget {
  const MyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = ref.watch(publisherPerformanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Performance')),
      body: performance.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(publisherPerformanceProvider),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(publisherPerformanceProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('OVERVIEW', theme),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                        label: 'Live', value: '${p.published}', color: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                        label: 'Drafts', value: '${p.drafts}', color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                        label: 'Removed', value: '${p.removed}', color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('BY CONTENT TYPE', theme),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final t in SubmissionType.values)
                      ListTile(
                        leading: Icon(_typeIcons[t]),
                        title: Text(_typeLabels[t]!),
                        trailing: Text('${p.byType[t] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('ENGAGEMENT (estimated)', theme),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: const Text('Estimated views'),
                      trailing: Text('${p.estimatedViews}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: const Text('Engagement rate'),
                      trailing: Text('${p.engagementPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'View/engagement figures are estimates for now.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.theme);
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
