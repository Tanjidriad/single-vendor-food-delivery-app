import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<({UserEntity user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });

  Future<({UserEntity user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> logout({required String refreshToken});

  Future<String?> sendPasswordResetOtp({required String email});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Sends a 6-digit OTP to [email] for post-registration account verification.
  Future<String?> sendVerifyEmailOtp({required String email});

  /// Verifies the 6-digit [code] that was sent to [email] during sign-up.
  Future<void> verifyEmailOtp({required String email, required String code});
}

typedef AuthResult = ({UserEntity user, String accessToken, String refreshToken});

/// Helper for use cases — map exceptions to [Failure] in repository impl later.
class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.failure);
  final Failure failure;

  @override
  String toString() => failure.message;
}
