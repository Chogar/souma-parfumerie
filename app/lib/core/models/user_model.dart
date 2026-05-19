class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.roleLabelFr,
    this.roleLabelAr,
  });

  final String id;
  final String username;
  final String fullName;
  final String role;

  final String? roleLabelFr;
  final String? roleLabelAr;

  bool get isManager => role == 'manager';
  bool get isGestionnaire => role == 'gestionnaire';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role_code'] as String? ?? map['role'] as String,
      roleLabelFr: map['label_fr'] as String?,
      roleLabelAr: map['label_ar'] as String?,
    );
  }
}
