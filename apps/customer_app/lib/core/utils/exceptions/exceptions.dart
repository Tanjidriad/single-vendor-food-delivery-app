/// App-level exception with user-facing message.
class AppException implements Exception {
  const AppException([this.message = 'Something went wrong. Please try again.']);

  final String message;

  /// Map common API / auth error codes from the NestJS backend.
  factory AppException.fromCode(String code) {
    switch (code) {
      case 'Unauthorized':
      case 'INVALID_CREDENTIALS':
        return const AppException('Invalid email or password.');
      case 'Conflict':
      case 'EMAIL_ALREADY_EXISTS':
        return const AppException('This email is already registered.');
      case 'Too Many Requests':
        return const AppException('Too many attempts. Try again later.');
      case 'NETWORK_ERROR':
        return const AppException('Check your internet connection.');
      default:
        return AppException(code);
    }
  }

  @override
  String toString() => message;
}

typedef TExceptions = AppException;
