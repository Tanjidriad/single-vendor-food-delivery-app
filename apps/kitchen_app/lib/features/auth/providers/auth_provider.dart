import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/push_notification_service.dart';

enum AuthStatus { initial, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isLoading;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
    bool? isLoading,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  ApiClient get _apiClient => ref.read(apiClientProvider);

  @override
  AuthState build() {
    Future.microtask(() => checkAuth());
    return AuthState();
  }

  Future<void> checkAuth() async {
    final token = await _apiClient.getToken();
    if (token != null) {
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(ref.read(pushNotificationServiceProvider).register());
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      final role = response.data['user']['role'];
      if (role != 'KITCHEN' && role != 'OWNER' && role != 'MANAGER') {
        throw Exception('Unauthorized role. Kitchen access only.');
      }

      await _apiClient.saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data['user'],
        isLoading: false,
      );
      unawaited(ref.read(pushNotificationServiceProvider).register());
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}
