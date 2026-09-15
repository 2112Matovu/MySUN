import 'package:flutter/material.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/bus_schedule.dart';

class BusScheduleTile extends StatelessWidget {
  const BusScheduleTile(this.schedule, {super.key});

  final BusSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = schedule.nextDeparture();
    final until = next.difference(DateTime.now());
    final suspended = !schedule.isActive;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  schedule.departureTime,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: suspended
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  suspended ? 'suspended' : 'in ${DateFmt.countdown(until)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 42, color: theme.dividerColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.routeName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${schedule.departurePoint}  →  ${schedule.destination}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(schedule.operatingDays),
                      if (schedule.estimatedDurationMinutes != null) ...[
                        const SizedBox(width: 6),
                        _Tag('~${schedule.estimatedDurationMinutes} min'),
                      ],
                    ],
                  ),
                  if (schedule.notes != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      schedule.notes!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}
