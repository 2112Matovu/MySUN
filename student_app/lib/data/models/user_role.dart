/// User roles per the integrated spec §7.1 role hierarchy.
enum UserRole {
  student,
  publisher,
  admin,
  minorAdmin;

  static UserRole fromJson(String? value) => switch (value) {
        'publisher' => UserRole.publisher,
        'admin' => UserRole.admin,
        'minor_admin' => UserRole.minorAdmin,
        _ => UserRole.student,
      };

  String toJson() => switch (this) {
        UserRole.student => 'student',
        UserRole.publisher => 'publisher',
        UserRole.admin => 'admin',
        UserRole.minorAdmin => 'minor_admin',
      };

  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.publisher => 'Publisher',
        UserRole.admin => 'Super Admin',
        UserRole.minorAdmin => 'Minor Admin',
      };

  /// Publishing module (§4.4) is visible only to publishers.
  bool get canPublish => this == UserRole.publisher;

  /// Admin-level accounts are redirected out of the student/staff app (§4.2).
  bool get isAdminLevel => this == UserRole.admin || this == UserRole.minorAdmin;
}
