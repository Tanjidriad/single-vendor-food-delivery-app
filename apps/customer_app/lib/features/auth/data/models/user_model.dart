import '../../domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final id = user['id'] as String? ?? user['sub'] as String?;
    if (id == null) {
      throw FormatException('Auth response missing user id');
    }
    return UserModel(
      id: id,
      email: user['email'] as String?,
      fullName: user['customerProfile']?['fullName'] as String? ??
          user['fullName'] as String?,
      role: user['role'] as String?,
      avatarUrl: user['customerProfile']?['avatarUrl'] as String?,
    );
  }

  final String id;
  final String? email;
  final String? fullName;
  final String? role;
  final String? avatarUrl;

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        fullName: fullName,
        role: role,
        avatarUrl: avatarUrl,
      );
}
