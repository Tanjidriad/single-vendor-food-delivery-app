import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, fullName, role, avatarUrl];
}
