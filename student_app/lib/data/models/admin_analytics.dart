/// §5.3 Analytics Dashboard + Main Dashboard "KEY METRICS"/"SYSTEM HEALTH".
/// Backed by `GET /api/v1/admin/analytics` once the backend exists (§9.6).
class AdminAnalytics {
  const AdminAnalytics({
    required this.dailyActiveUsers,
    required this.monthlyActiveUsers,
    required this.totalUsers,
    required this.publisherCount,
    required this.announcementsPublished,
    required this.eventsCreated,
    required this.avgEngagementPercent,
    required this.apiOnline,
    required this.databaseHealthPercent,
    required this.storageUsedPercent,
  });

  final int dailyActiveUsers;
  final int monthlyActiveUsers;
  final int totalUsers;
  final int publisherCount;
  final int announcementsPublished;
  final int eventsCreated;
  final double avgEngagementPercent;
  final bool apiOnline;
  final double databaseHealthPercent;
  final double storageUsedPercent;

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) => AdminAnalytics(
        dailyActiveUsers: json['daily_active_users'] as int,
        monthlyActiveUsers: json['monthly_active_users'] as int,
        totalUsers: json['total_users'] as int,
        publisherCount: json['publisher_count'] as int,
        announcementsPublished: json['announcements_published'] as int,
        eventsCreated: json['events_created'] as int,
        avgEngagementPercent: (json['avg_engagement_percent'] as num).toDouble(),
        apiOnline: json['api_online'] as bool? ?? true,
        databaseHealthPercent:
            (json['database_health_percent'] as num?)?.toDouble() ?? 100,
        storageUsedPercent: (json['storage_used_percent'] as num?)?.toDouble() ?? 0,
      );

  static const mock = AdminAnalytics(
    dailyActiveUsers: 1240,
    monthlyActiveUsers: 3450,
    totalUsers: 3700,
    publisherCount: 45,
    announcementsPublished: 124,
    eventsCreated: 31,
    avgEngagementPercent: 18.5,
    apiOnline: true,
    databaseHealthPercent: 98.2,
    storageUsedPercent: 67,
  );
}
