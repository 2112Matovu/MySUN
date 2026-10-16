/// Which kinds of notification the user wants (profile settings). Mirrors
/// `GET/PUT /api/v1/notifications/preferences`. Moderation notices about the
/// user's own content are always delivered and have no switch.
enum NotificationCategory {
  announcements('announcements', 'Announcements', 'New campus announcements'),
  events('events', 'New events', 'When a new event is published'),
  reminders('reminders', 'Event reminders',
      'A day and an hour before events you registered for or saved'),
  transport('transport', 'Transport and bookings',
      'Updates on your boda ride requests');

  const NotificationCategory(this.apiKey, this.title, this.subtitle);
  final String apiKey;
  final String title;
  final String subtitle;
}

class NotificationPrefs {
  const NotificationPrefs([this._on = const {}]);

  final Map<NotificationCategory, bool> _on;

  /// Everything is on until the user switches it off.
  bool isOn(NotificationCategory c) => _on[c] ?? true;

  NotificationPrefs toggled(NotificationCategory c, bool value) =>
      NotificationPrefs({
        for (final k in NotificationCategory.values) k: isOn(k),
        c: value,
      });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs({
        for (final c in NotificationCategory.values)
          c: json[c.apiKey] as bool? ?? true,
      });

  Map<String, dynamic> toJson() => {
        for (final c in NotificationCategory.values) c.apiKey: isOn(c),
      };
}
