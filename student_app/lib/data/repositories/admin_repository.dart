import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/admin_analytics.dart';
import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';

/// User directory + role management (§5.3 User Management, §7.3 Role
/// Assignment) and system-wide metrics (§5.3 Analytics/Dashboard). Maps onto
/// `GET/PATCH /api/v1/admin/users`, `GET /api/v1/admin/analytics` (§9.5-9.6).
abstract interface class AdminRepository {
  Future<List<UserProfile>> listUsers({UserRole? role});

  Future<UserProfile> updateRole(String userId, UserRole newRole);

  Future<AdminAnalytics> analytics();

  /// Newest-first log of administrator actions (`GET /admin/audit`).
  Future<List<AuditEntry>> auditLog({int limit = 100});

  /// All users as CSV text (`GET /admin/users/export.csv`).
  Future<String> exportUsersCsv();
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorName,
    this.targetType,
    this.targetId,
    this.detail = const {},
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? actorName;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> detail;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as String,
        action: json['action'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        actorName: json['actor_name'] as String?,
        targetType: json['target_type'] as String?,
        targetId: json['target_id'] as String?,
        detail: (json['detail'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class MockAdminRepository implements AdminRepository {
  static final List<UserProfile> _directory = [
    const UserProfile(
      id: 'usr-005',
      name: 'Dr. Okot',
      email: 'okot@sun.ac.ug',
      role: UserRole.admin,
      faculty: 'Office of the DVC',
    ),
    const UserProfile(
      id: 'usr-010',
      name: 'Sarah Akena',
      email: 'publisher@sun.ac.ug',
      role: UserRole.publisher,
      faculty: 'HR Department',
    ),
    const UserProfile(
      id: 'usr-004',
      name: 'James Mburu',
      email: 'james.mburu@sun.ac.ug',
      role: UserRole.minorAdmin,
      faculty: 'Student Affairs',
    ),
    const UserProfile(
      id: 'usr-006',
      name: 'Peter Ocen',
      email: 'peter.ocen@sun.ac.ug',
      role: UserRole.publisher,
      faculty: 'ICT Directorate',
    ),
    const UserProfile(
      id: 'usr-001',
      name: 'Amos Ekiring',
      email: 'student@sun.ac.ug',
      role: UserRole.student,
      studentId: 'SU/2023/BSC/0142',
      faculty: 'Faculty of Science & Education',
      program: 'BSc. Computer Science',
    ),
    const UserProfile(
      id: 'usr-002',
      name: 'John Opiyo',
      email: 'john.opiyo@sun.ac.ug',
      role: UserRole.student,
      faculty: 'Faculty of Engineering & Applied Sciences',
      program: 'Year 2',
    ),
    const UserProfile(
      id: 'usr-003',
      name: 'Grace Aciro',
      email: 'grace.aciro@sun.ac.ug',
      role: UserRole.student,
      faculty: 'Faculty of Business & Development Studies',
      program: 'Year 3',
    ),
  ];

  @override
  Future<List<UserProfile>> listUsers({UserRole? role}) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (role == null) return List.unmodifiable(_directory);
    return _directory.where((u) => u.role == role).toList();
  }

  @override
  Future<UserProfile> updateRole(String userId, UserRole newRole) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final i = _directory.indexWhere((u) => u.id == userId);
    if (i == -1) throw StateError('User $userId not found');
    final updated = _directory[i].copyWith(role: newRole);
    _directory[i] = updated;
    return updated;
  }

  @override
  Future<AdminAnalytics> analytics() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return AdminAnalytics.mock;
  }

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) async => const [];

  @override
  Future<String> exportUsersCsv() async {
    final rows = _directory.map((u) => '${u.id},${u.name},${u.email},${u.role.toJson()}');
    return ['id,name,email,role', ...rows].join('\n');
  }
}

class HttpAdminRepository implements AdminRepository {
  HttpAdminRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<UserProfile>> listUsers({UserRole? role}) async {
    try {
      final res = await _dio.get('/admin/users', queryParameters: {
        if (role != null) 'role': role.toJson(),
      });
      return (res.data as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<UserProfile> updateRole(String userId, UserRole newRole) async {
    try {
      final res = await _dio.patch('/admin/users/$userId/role', data: {
        'new_role': newRole.toJson(),
      });
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<AdminAnalytics> analytics() async {
    try {
      final res = await _dio.get('/admin/analytics');
      return AdminAnalytics.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) async {
    try {
      final res = await _dio.get('/admin/audit', queryParameters: {'limit': limit});
      return (res.data as List)
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<String> exportUsersCsv() async {
    try {
      final res = await _dio.get<String>(
        '/admin/users/export.csv',
        options: Options(responseType: ResponseType.plain),
      );
      return res.data ?? '';
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
