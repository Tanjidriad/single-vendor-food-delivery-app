import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../errors/failures.dart';
import '../realtime/socket_service.dart';
import '../storage/token_storage.dart';
import 'retry_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});

/// In-memory access token for authenticated API calls.
final authTokenProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<Dio>((ref) {
  final baseDio = ref.watch(dioProvider);

  final client = Dio(baseDio.options.copyWith(baseUrl: AppConfig.apiBaseUrl));

  client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        final path = error.requestOptions.path;
        if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
          return handler.next(error);
        }

        try {
          final newAccessToken = await ref.read(tokenRefresherProvider).refresh();
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await client.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await ref.read(tokenRefresherProvider).clearSession();
          return handler.next(error);
        }
      },
    ),
  );

  // Retries idempotent GETs on transient 5xx/network errors with backoff.
  // Added after auth so 401 refresh runs first and only true transient
  // failures reach the retry logic.
  client.interceptors.add(retryInterceptor(client));

  return client;
});

/// Coordinates access-token refresh. De-duplicates concurrent 401s so only one
/// network refresh runs at a time, and persists the rotated tokens.
final tokenRefresherProvider =
    Provider<TokenRefresher>((ref) => TokenRefresher(ref));

class TokenRefresher {
  TokenRefresher(this._ref);

  final Ref _ref;

  /// In-flight refresh shared by concurrent callers (replaces the previous
  /// top-level mutable global, so the dedup state is scoped + testable).
  Completer<String?>? _inFlight;

  /// Refreshes the access token, returning the new value. Concurrent callers
  /// await the same in-flight refresh rather than triggering several.
  Future<String> refresh() async {
    final existing = _inFlight;
    if (existing != null) {
      final token = await existing.future;
      if (token == null || token.isEmpty) {
        throw const AuthFailure('Token refresh failed.');
      }
      return token;
    }

    final completer = Completer<String?>();
    _inFlight = completer;
    try {
      final tokenStorage = _ref.read(tokenStorageProvider);
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        throw const AuthFailure('No refresh token.');
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data?['accessToken'] as String?;
      final newRefreshToken = response.data?['refreshToken'] as String?;
      if (newAccessToken == null || newRefreshToken == null) {
        completer.complete(null);
        throw const ServerFailure('Invalid refresh response.');
      }

      await tokenStorage.writeTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      _scheduleAuthUpdate(newAccessToken);
      // Reconnect the socket with the new token, deferred off the async gap.
      unawaited(Future.microtask(() {
        _ref.read(socketServiceProvider).reconnectWithToken(newAccessToken);
      }));
      completer.complete(newAccessToken);
      return newAccessToken;
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  /// Clears the persisted session after an unrecoverable auth failure.
  Future<void> clearSession() async {
    unawaited(Future.microtask(() async {
      await _ref.read(tokenStorageProvider).clear();
      _ref.read(authTokenProvider.notifier).state = null;
    }));
  }

  /// Schedules the in-memory token write outside the Dio interceptor/async gap
  /// so Riverpod does not assert during provider rebuilds.
  void _scheduleAuthUpdate(String? accessToken) {
    Future.microtask(() {
      _ref.read(authTokenProvider.notifier).state = accessToken;
    });
  }
}
