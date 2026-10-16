import 'package:flutter/material.dart';

enum ServiceCategory {
  food('food', 'Food', Icons.restaurant_outlined),
  health('health', 'Health', Icons.local_hospital_outlined),
  itSupport('it_support', 'IT Support', Icons.computer_outlined),
  library('library', 'Library', Icons.local_library_outlined);

  const ServiceCategory(this.apiValue, this.label, this.icon);
  final String apiValue;
  final String label;
  final IconData icon;

  static ServiceCategory fromJson(String s) => ServiceCategory.values
      .firstWhere((c) => c.apiValue == s, orElse: () => ServiceCategory.food);
}

/// A food, health, IT-support or library service on campus.
class CampusService {
  const CampusService({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    this.location,
    this.openingHours,
    this.contactPhone,
  });

  final String id;
  final ServiceCategory category;
  final String name;
  final String? description;
  final String? location;
  final String? openingHours;
  final String? contactPhone;

  factory CampusService.fromJson(Map<String, dynamic> json) => CampusService(
        id: json['id'] as String,
        category: ServiceCategory.fromJson(json['category'] as String),
        name: json['name'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        openingHours: json['opening_hours'] as String?,
        contactPhone: json['contact_phone'] as String?,
      );
}
