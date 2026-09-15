import 'package:flutter/material.dart';

import 'package:mysun_app/core/theme/app_colors.dart';

/// Announcement categories per spec §4.2 (plus a leading "All" filter option).
const List<String> announcementCategories = <String>[
  'All',
  'Academic',
  'Social',
  'Sports',
  'Administration',
  'Clubs',
  'Transport',
];

/// Event categories per spec §4.2.
const List<String> eventCategories = <String>[
  'All',
  'Academic',
  'Sports',
  'Social',
  'Clubs',
  'Workshops',
];

IconData categoryIcon(String category) {
  switch (category) {
    case 'Academic':
      return Icons.school_outlined;
    case 'Social':
      return Icons.celebration_outlined;
    case 'Sports':
      return Icons.sports_soccer_outlined;
    case 'Administration':
      return Icons.account_balance_outlined;
    case 'Clubs':
      return Icons.groups_outlined;
    case 'Workshops':
      return Icons.build_outlined;
    case 'Transport':
      return Icons.directions_bus_outlined;
    default:
      return Icons.campaign_outlined;
  }
}

Color categoryColor(String category) {
  switch (category) {
    case 'Academic':
      return AppColors.academic;
    case 'Social':
      return AppColors.social;
    case 'Sports':
      return AppColors.sports;
    case 'Administration':
      return AppColors.administration;
    case 'Clubs':
      return AppColors.clubs;
    case 'Workshops':
      return AppColors.workshops;
    case 'Transport':
      return AppColors.transport;
    default:
      return AppColors.brandSun;
  }
}

IconData serviceTypeIcon(String serviceType) {
  switch (serviceType) {
    case 'boda':
      return Icons.two_wheeler_outlined;
    case 'bus':
      return Icons.directions_bus_outlined;
    case 'matatu':
      return Icons.airport_shuttle_outlined;
    case 'taxi':
    default:
      return Icons.local_taxi_outlined;
  }
}

IconData notificationIcon(String type) {
  switch (type) {
    case 'announcement':
      return Icons.campaign_outlined;
    case 'event':
      return Icons.event_outlined;
    case 'reminder':
      return Icons.alarm_outlined;
    case 'transport':
      return Icons.directions_bus_outlined;
    case 'system':
    default:
      return Icons.info_outline;
  }
}
