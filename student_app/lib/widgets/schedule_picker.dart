import 'package:flutter/material.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';

/// Asks for a date, then a time, and returns the combined local date-time,
/// or null if the user backs out. Rejects anything under two minutes ahead
/// (the server needs at least one) with a message.
Future<DateTime?> pickFutureDateTime(BuildContext context,
    {DateTime? initial}) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: (initial != null && initial.isAfter(now)) ? initial : now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
        initial ?? now.add(const Duration(hours: 1))),
  );
  if (time == null || !context.mounted) return null;
  final picked =
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (picked.isBefore(now.add(const Duration(minutes: 2)))) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick a time at least a few minutes ahead')),
    );
    return null;
  }
  return picked;
}

String describeSchedule(DateTime when) =>
    '${DateFmt.dayLabel(when)}, ${DateFmt.time(when)}';

/// "Schedule for later" switch plus the chosen date and time. [value] null
/// means publish immediately.
class SchedulePicker extends StatelessWidget {
  const SchedulePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.what = 'it',
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Used in the subtitle: "Goes live ..." refers to this.
  final String what;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Schedule for later'),
          subtitle: Text(value == null
              ? 'Goes live as soon as you publish'
              : 'Goes live ${describeSchedule(value!)}'),
          value: value != null,
          onChanged: (on) async {
            if (!on) return onChanged(null);
            final picked = await pickFutureDateTime(context, initial: value);
            if (picked != null) onChanged(picked);
          },
        ),
        if (value != null)
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await pickFutureDateTime(context, initial: value);
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.schedule_send_outlined),
            label: const Text('Change date and time'),
          ),
      ],
    );
  }
}
