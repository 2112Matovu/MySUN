enum BookingStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  cancelled('Cancelled'),
  completed('Completed');

  const BookingStatus(this.label);
  final String label;

  static BookingStatus fromJson(String s) =>
      BookingStatus.values.firstWhere((v) => v.name == s,
          orElse: () => BookingStatus.pending);

  /// Still open: the student can cancel it and the rider can act on it.
  bool get isActive => this == pending || this == accepted;
}

/// A student's ride request to a boda rider (`bookings` table).
class Booking {
  const Booking({
    required this.id,
    required this.providerId,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.createdAt,
    this.requestedTime,
    this.note,
    this.providerName,
    this.providerPhone,
    this.studentName,
  });

  final String id;
  final String providerId;
  final String pickup;
  final String destination;
  final BookingStatus status;
  final DateTime createdAt;

  /// Null means "as soon as possible".
  final DateTime? requestedTime;
  final String? note;
  final String? providerName;
  final String? providerPhone;
  final String? studentName;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        providerId: json['provider_id'] as String,
        pickup: json['pickup'] as String,
        destination: json['destination'] as String,
        status: BookingStatus.fromJson(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        requestedTime: json['requested_time'] == null
            ? null
            : DateTime.parse(json['requested_time'] as String).toLocal(),
        note: json['note'] as String?,
        providerName: json['provider_name'] as String?,
        providerPhone: json['provider_phone'] as String?,
        studentName: json['student_name'] as String?,
      );
}
