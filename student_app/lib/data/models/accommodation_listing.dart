enum AccommodationType {
  hostel,
  rental;

  String get label => this == AccommodationType.hostel ? 'Hostel' : 'Rental';

  /// Hostels are billed per semester; independent rentals per month.
  String get priceUnit => this == AccommodationType.hostel ? 'semester' : 'month';

  static AccommodationType fromJson(String? value) =>
      value == 'rental' ? AccommodationType.rental : AccommodationType.hostel;

  String toJson() => this == AccommodationType.hostel ? 'hostel' : 'rental';
}

/// How rooms are made available.
enum RoomSharingType {
  shared,
  private,
  both;

  String get label => switch (this) {
        RoomSharingType.shared => 'Shared rooms',
        RoomSharingType.private => 'Private rooms',
        RoomSharingType.both => 'Shared & private',
      };

  static RoomSharingType fromJson(String? value) => switch (value) {
        'private' => RoomSharingType.private,
        'both' => RoomSharingType.both,
        _ => RoomSharingType.shared,
      };

  String toJson() => switch (this) {
        RoomSharingType.shared => 'shared',
        RoomSharingType.private => 'private',
        RoomSharingType.both => 'both',
      };
}

/// An accommodation listing (spec §6.4 `accommodation_listings`, extended
/// with pricing/gazetted-status/room-sharing/images per the publisher's
/// requirements). Publisher-submitted — see [PublisherRepository].
class AccommodationListing {
  const AccommodationListing({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.price,
    required this.isGazetted,
    required this.roomSharing,
    required this.contactPhone,
    this.imageUrls = const [],
    this.description,
    this.publisherName,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final AccommodationType type;
  final String location;

  /// Rent in UGX, billed per [AccommodationType.priceUnit] (semester for
  /// hostels, month for independent rentals).
  final int price;

  /// Whether the hostel is registered/approved by the university
  /// (gazetted) or an independent, non-gazetted facility.
  final bool isGazetted;
  final RoomSharingType roomSharing;
  final String contactPhone;
  final List<String> imageUrls;
  final String? description;
  final String? publisherName;
  final bool isAvailable;

  factory AccommodationListing.fromJson(Map<String, dynamic> json) =>
      AccommodationListing(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccommodationType.fromJson(json['type'] as String?),
        location: json['location'] as String,
        price: json['price'] as int? ?? 0,
        isGazetted: json['is_gazetted'] as bool? ?? false,
        roomSharing: RoomSharingType.fromJson(json['room_sharing'] as String?),
        contactPhone: json['contact_phone'] as String? ?? '',
        imageUrls: (json['image_urls'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        description: json['description'] as String?,
        publisherName: json['publisher_name'] as String?,
        isAvailable: json['is_available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toJson(),
        'location': location,
        'price': price,
        'is_gazetted': isGazetted,
        'room_sharing': roomSharing.toJson(),
        'contact_phone': contactPhone,
        'image_urls': imageUrls,
        'description': description,
        'publisher_name': publisherName,
        'is_available': isAvailable,
      };
}
