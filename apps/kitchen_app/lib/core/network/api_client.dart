import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  static const String _accessTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  final _storage = const FlutterSecureStorage();

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _isRefreshing = false;
  final List<_RetryRequest> _pendingRequests = [];
  final _tokenRefreshedController = StreamController<void>.broadcast();

  Stream<void> get tokenRefreshedStream => _tokenRefreshedController.stream;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && !_isRefreshPath(e.requestOptions.path)) {
            final retried = await _handleTokenRefresh(e);
            if (retried != null) {
              return handler.resolve(retried);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  bool _isRefreshPath(String path) {
    return path.contains('/auth/refresh') || path.contains('/auth/login');
  }

  Future<Response?> _handleTokenRefresh(DioException error) async {
    if (_isRefreshing) {
      final completer = Completer<Response?>();
      _pendingRequests.add(_RetryRequest(error.requestOptions, completer));
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _rejectPending();
        return null;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ));

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;
        if (newAccessToken != null && newRefreshToken != null) {
          await saveTokens(newAccessToken, newRefreshToken);
          if (!_tokenRefreshedController.isClosed) {
            _tokenRefreshedController.add(null);
          }
          final retryResponse = await _retryRequest(error.requestOptions, newAccessToken);
          _resolvePending(newAccessToken);
          return retryResponse;
        }
      }

      _rejectPending();
      return null;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      _rejectPending();
      await clearTokens();
      // We could broadcast an event here to trigger logout.
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response> _retryRequest(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch(options);
  }

  void _resolvePending(String newToken) {
    for (final pending in _pendingRequests) {
      _retryRequest(pending.options, newToken).then(
        (r) => pending.completer.complete(r),
        onError: (e) => pending.completer.completeError(e),
      );
    }
    _pendingRequests.clear();
  }

  void _rejectPending() {
    for (final pending in _pendingRequests) {
      pending.completer.complete(null);
    }
    _pendingRequests.clear();
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _dio.delete(path, data: data);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    return _cachedRefreshToken;
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class _RetryRequest {
  final RequestOptions options;
  final Completer<Response?> completer;

  _RetryRequest(this.options, this.completer);
}
