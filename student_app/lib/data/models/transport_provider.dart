/// A verified transport provider in the directory (spec §4.2 `transport_providers`).
class TransportProvider {
  const TransportProvider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.serviceType,
    this.contactPerson,
    this.imageUrl,
    this.isVerified = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.operatingHours,
    this.serviceAreas = const [],
  });

  final String id;
  final String name;
  final String phoneNumber;

  /// One of: `boda`, `taxi`, `bus`, `matatu`.
  final String serviceType;
  final String? contactPerson;
  final String? imageUrl;
  final bool isVerified;
  final double rating;
  final int ratingCount;
  final String? operatingHours;
  final List<String> serviceAreas;

  factory TransportProvider.fromJson(Map<String, dynamic> json) =>
      TransportProvider(
        id: json['id'] as String,
        name: json['name'] as String,
        phoneNumber: json['phone_number'] as String,
        serviceType: json['service_type'] as String? ?? 'taxi',
        contactPerson: json['contact_person'] as String?,
        imageUrl: json['image_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: json['rating_count'] as int? ?? 0,
        operatingHours: json['operating_hours'] as String?,
        serviceAreas: (json['service_areas'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'service_type': serviceType,
        'contact_person': contactPerson,
        'image_url': imageUrl,
        'is_verified': isVerified,
        'rating': rating,
        'rating_count': ratingCount,
        'operating_hours': operatingHours,
        'service_areas': serviceAreas,
      };
}
