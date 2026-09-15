import 'package:mysun_app/data/models/user_role.dart';

/// The signed-in student/staff account (spec §8.1 `users` table). Until the
/// backend lands, accounts live in [MockAuthRepository] and are cached here.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.faculty,
    this.program,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? studentId;
  final String? faculty;
  final String? program;
  final String? imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.fromJson(json['role'] as String?),
        studentId: json['student_id'] as String?,
        faculty: json['faculty'] as String?,
        program: json['program'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.toJson(),
        'student_id': studentId,
        'faculty': faculty,
        'program': program,
        'image_url': imageUrl,
      };

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? studentId,
    String? faculty,
    String? program,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        studentId: studentId ?? this.studentId,
        faculty: faculty ?? this.faculty,
        program: program ?? this.program,
        imageUrl: imageUrl,
      );
}
