import 'package:dio/dio.dart';

/// Whether a failure is worth retrying: network/timeout issues or 5xx server
/// errors. Client errors (4xx) and successful-but-rejected statuses are not.
bool isTransientFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      final code = error.response?.statusCode;
      return code != null && code >= 500 && code <= 599;
  }
}

/// Retries idempotent (GET) requests on transient failures with exponential
/// backoff. Non-idempotent methods are never retried (they may have side
/// effects), and 4xx errors pass straight through.
///
/// [client] is the Dio used to replay the request; pass [baseDelay] = zero in
/// tests to avoid real waiting.
Interceptor retryInterceptor(
  Dio client, {
  int maxRetries = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
}) {
  return InterceptorsWrapper(
    onError: (error, handler) async {
      final options = error.requestOptions;
      final attempt = (options.extra['retry_attempt'] as int?) ?? 0;
      final isIdempotent = options.method.toUpperCase() == 'GET';

      if (!isIdempotent ||
          !isTransientFailure(error) ||
          attempt >= maxRetries) {
        return handler.next(error);
      }

      // Exponential backoff: baseDelay * 2^attempt (e.g. 300ms, 600ms, 1.2s).
      await Future<void>.delayed(baseDelay * (1 << attempt));
      options.extra['retry_attempt'] = attempt + 1;

      try {
        final response = await client.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    },
  );
}
