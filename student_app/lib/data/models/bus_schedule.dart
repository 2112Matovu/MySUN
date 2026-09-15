/// A campus bus departure (spec §4.2 `bus_schedules`).
class BusSchedule {
  const BusSchedule({
    required this.id,
    required this.routeName,
    required this.departurePoint,
    required this.destination,
    required this.departureTime,
    this.estimatedDurationMinutes,
    this.operatingDays = 'Daily',
    this.status = 'active',
    this.notes,
  });

  final String id;
  final String routeName;
  final String departurePoint;
  final String destination;

  /// 24-hour `HH:mm`.
  final String departureTime;
  final int? estimatedDurationMinutes;
  final String operatingDays;

  /// One of: `active`, `suspended`, `cancelled`.
  final String status;
  final String? notes;

  factory BusSchedule.fromJson(Map<String, dynamic> json) => BusSchedule(
        id: json['id'] as String,
        routeName: json['route_name'] as String,
        departurePoint: json['departure_point'] as String,
        destination: json['destination'] as String,
        departureTime: (json['departure_time'] as String).substring(0, 5),
        estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
        operatingDays: json['operating_days'] as String? ?? 'Daily',
        status: json['status'] as String? ?? 'active',
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_name': routeName,
        'departure_point': departurePoint,
        'destination': destination,
        'departure_time': departureTime,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'operating_days': operatingDays,
        'status': status,
        'notes': notes,
      };

  int get _hour => int.parse(departureTime.split(':')[0]);
  int get _minute => int.parse(departureTime.split(':')[1]);

  /// Next wall-clock departure at or after [from] (defaults to now).
  DateTime nextDeparture([DateTime? from]) {
    final now = from ?? DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, _hour, _minute);
    if (!dt.isAfter(now)) dt = dt.add(const Duration(days: 1));
    return dt;
  }

  bool get isActive => status == 'active';
}
