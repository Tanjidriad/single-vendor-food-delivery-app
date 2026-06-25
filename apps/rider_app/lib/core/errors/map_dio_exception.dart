import 'package:dio/dio.dart';

import 'failures.dart';

/// Maps a [DioException] to a domain-level [Failure] so repositories can throw
/// a typed, UI-friendly error instead of leaking transport details.
///
/// Kept in sync with `customer_app`'s copy; both will move to a shared
/// `core_errors` package in the planned Melos workspace.
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
      return const NetworkFailure('Secure connection failed.');
    case DioExceptionType.cancel:
      return const NetworkFailure('Request was cancelled.');
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final serverMessage = _serverMessage(e.response?.data);
      if (status == 401 || status == 403) {
        return AuthFailure(
          serverMessage ?? 'Your session has expired. Please sign in again.',
        );
      }
      return ServerFailure(
        serverMessage ?? 'Something went wrong. Please try again.',
      );
    case DioExceptionType.unknown:
      return const ServerFailure();
  }
}

/// Extracts a human-readable message from a JSON error body
/// (`{"message": ...}` or `{"error": ...}`), if present.
String? _serverMessage(Object? data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'];
    if (message is String && message.isNotEmpty) return message;
    // Validation errors often arrive as a list of messages.
    if (message is List && message.isNotEmpty) return message.first.toString();
  }
  return null;
}
