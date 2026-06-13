import '../../domain/repositories/auth_repository.dart';

/// Human-readable message for auth UI snackbars and dialogs.
String authErrorMessage(Object error) {
  if (error is AuthRepositoryException) return error.failure.message;
  return error.toString();
}
