import 'package:intl/intl.dart';

/// Human-friendly date/time formatting used across the app.
abstract final class DateFmt {
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _dayMonth = DateFormat('EEE, d MMM');
  static final DateFormat _fullDate = DateFormat('EEE, d MMM yyyy');

  static String time(DateTime dt) => _time.format(dt);

  static String full(DateTime dt) =>
      '${_fullDate.format(dt)} • ${_time.format(dt)}';

  /// "Today", "Tomorrow", "Yesterday", else "Wed, 12 Mar".
  static String dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return _dayMonth.format(dt);
  }

  /// Compact "time ago" for feed items: "just now", "5m", "3h", "2d", else date.
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dayMonth.format(dt);
  }

  /// Countdown to a future moment: "2d 4h", "3h 12m", "8m", "Starting now".
  static String countdown(Duration d) {
    if (d.isNegative) return 'Started';
    if (d.inMinutes < 1) return 'Starting now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }
}
