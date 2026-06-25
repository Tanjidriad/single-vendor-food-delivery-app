import 'package:equatable/equatable.dart';

/// Domain-level error representation (UI / use cases consume this).
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  /// UI-facing string. Lets helpers like `friendlyErrorMessage` and
  /// `error.toString()` surface the human message instead of the type name.
  @override
  String toString() => message;
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}
