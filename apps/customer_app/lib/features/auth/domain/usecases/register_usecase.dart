import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repository.register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}
