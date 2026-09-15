import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/admin_analytics.dart';
import 'package:mysun_app/providers/admin_provider.dart';
import 'package:mysun_app/widgets/state_views.dart';

String _buildReport(AdminAnalytics a) {
  final generatedAt = DateTime.now();
  return '''
MySun Admin Report
Generated: ${generatedAt.toIso8601String()}

USER METRICS
Daily active users: ${a.dailyActiveUsers}
Monthly active users: ${a.monthlyActiveUsers}
Total users: ${a.totalUsers}
Publishers: ${a.publisherCount}

CONTENT METRICS
Announcements published: ${a.announcementsPublished}
Events created: ${a.eventsCreated}
Average engagement: ${a.avgEngagementPercent.toStringAsFixed(1)}%
''';
}

void _showReport(BuildContext context, AdminAnalytics a) {
  final report = _buildReport(a);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Admin Report'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(report, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy'),
        ),
      ],
    ),
  );
}

/// §5.3 Analytics Dashboard — Super Admin only.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: analytics.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: '$e', onRetry: () => ref.invalidate(adminAnalyticsProvider)),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('USER METRICS'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _MetricTile('Daily active users', '${a.dailyActiveUsers}'),
                  _MetricTile('Monthly active users', '${a.monthlyActiveUsers}'),
                  _MetricTile('Total users', '${a.totalUsers}'),
                  _MetricTile('Publishers', '${a.publisherCount}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('CONTENT METRICS'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _MetricTile(
                      'Announcements published', '${a.announcementsPublished}'),
                  _MetricTile('Events created', '${a.eventsCreated}'),
                  _MetricTile('Avg engagement',
                      '${a.avgEngagementPercent.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _showReport(context, a),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6));
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
