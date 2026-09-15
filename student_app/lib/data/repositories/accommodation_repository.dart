import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/accommodation_listing.dart';

/// Maps onto `GET/POST /api/v1/services/accommodation` once the extensible
/// services backend exists (spec §6.2, §6.4).
abstract interface class AccommodationRepository {
  Future<List<AccommodationListing>> list({AccommodationType? type});

  Future<AccommodationListing> getById(String id);

  Future<AccommodationListing> create(AccommodationListing listing);

  /// Admin removal for content that breaks the terms of service (§5.1).
  Future<void> delete(String id);
}

class MockAccommodationRepository implements AccommodationRepository {
  static final List<AccommodationListing> _listings = [
    const AccommodationListing(
      id: 'acc-001',
      name: 'Green Valley Hostel',
      type: AccommodationType.hostel,
      location: '5 min walk from Main Gate',
      price: 900000,
      isGazetted: true,
      roomSharing: RoomSharingType.both,
      contactPhone: '+256 700 111 222',
      imageUrls: [
        'https://picsum.photos/seed/mysun-hostel-1/800/500',
        'https://picsum.photos/seed/mysun-hostel-1b/800/500',
      ],
      description:
          'University-registered hostel with 24/7 security, water and power '
          'backup. Both shared (2-in-a-room) and private single rooms '
          'available.',
      publisherName: 'Green Valley Estates',
    ),
    const AccommodationListing(
      id: 'acc-002',
      name: 'Teso Students Lodge',
      type: AccommodationType.hostel,
      location: 'Arapai Road, 10 min from campus',
      price: 650000,
      isGazetted: true,
      roomSharing: RoomSharingType.shared,
      contactPhone: '+256 772 333 444',
      imageUrls: ['https://picsum.photos/seed/mysun-hostel-2/800/500'],
      description:
          'Affordable shared rooms (3-in-a-room), communal kitchen and '
          'reading room. Registered with the Dean of Students office.',
      publisherName: 'Teso Students Lodge Management',
    ),
    const AccommodationListing(
      id: 'acc-003',
      name: 'Sunrise Self-Contained Rentals',
      type: AccommodationType.rental,
      location: 'Soroti Town, near Independence Square',
      price: 400000,
      isGazetted: false,
      roomSharing: RoomSharingType.private,
      contactPhone: '+256 753 555 666',
      imageUrls: [
        'https://picsum.photos/seed/mysun-rental-1/800/500',
        'https://picsum.photos/seed/mysun-rental-1b/800/500',
        'https://picsum.photos/seed/mysun-rental-1c/800/500',
      ],
      description:
          'Independent self-contained single rooms, not university-'
          'registered. Own kitchenette and bathroom. Ideal for finalists '
          'and staff.',
      publisherName: 'Sunrise Properties',
    ),
    const AccommodationListing(
      id: 'acc-004',
      name: 'Campus View Annex',
      type: AccommodationType.hostel,
      location: 'Directly opposite the Main Library',
      price: 750000,
      isGazetted: false,
      roomSharing: RoomSharingType.both,
      contactPhone: '+256 701 777 888',
      imageUrls: ['https://picsum.photos/seed/mysun-hostel-3/800/500'],
      description:
          'Privately run annex, not yet gazetted by the university. Choice '
          'of 2-in-a-room sharing or private single rooms.',
      publisherName: 'Campus View Annex',
      isAvailable: false,
    ),
  ];

  @override
  Future<List<AccommodationListing>> list({AccommodationType? type}) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (type == null) return List.unmodifiable(_listings);
    return _listings.where((l) => l.type == type).toList();
  }

  @override
  Future<AccommodationListing> getById(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _listings.firstWhere(
      (l) => l.id == id,
      orElse: () => throw StateError('Accommodation listing $id not found'),
    );
  }

  @override
  Future<AccommodationListing> create(AccommodationListing listing) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final saved = AccommodationListing(
      id: 'acc-${DateTime.now().millisecondsSinceEpoch}',
      name: listing.name,
      type: listing.type,
      location: listing.location,
      price: listing.price,
      isGazetted: listing.isGazetted,
      roomSharing: listing.roomSharing,
      contactPhone: listing.contactPhone,
      imageUrls: listing.imageUrls,
      description: listing.description,
      publisherName: listing.publisherName,
    );
    _listings.insert(0, saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _listings.removeWhere((l) => l.id == id);
  }
}

class HttpAccommodationRepository implements AccommodationRepository {
  HttpAccommodationRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<AccommodationListing>> list({AccommodationType? type}) async {
    try {
      final res = await _dio.get('/accommodation', queryParameters: {
        if (type != null) 'type': type.toJson(),
      });
      return (res.data as List)
          .map((e) => AccommodationListing.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<AccommodationListing> getById(String id) async {
    try {
      final res = await _dio.get('/accommodation/$id');
      return AccommodationListing.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<AccommodationListing> create(AccommodationListing listing) async {
    try {
      final res = await _dio.post('/accommodation', data: {
        'name': listing.name,
        'type': listing.type.toJson(),
        'location': listing.location,
        'price': listing.price,
        'is_gazetted': listing.isGazetted,
        'room_sharing': listing.roomSharing.toJson(),
        'contact_phone': listing.contactPhone,
        'image_urls': listing.imageUrls,
        'description': listing.description,
      });
      return AccommodationListing.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/accommodation/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
