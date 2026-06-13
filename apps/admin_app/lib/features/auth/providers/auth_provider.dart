import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  @override
  AuthState build() {
    _checkInitialAuth();
    return AuthState.initial;
  }

  Future<void> _checkInitialAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      ref.read(authTokenProvider.notifier).state = token;
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.login(email, password);
      
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        
        ref.read(authTokenProvider.notifier).state = accessToken;
        state = AuthState.authenticated;
      } else {
        _errorMessage = 'Invalid response from server';
        state = AuthState.error;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      state = AuthState.error;
      // Revert back to unauthenticated after error to allow retry
      Future.delayed(const Duration(seconds: 3), () {
        if (state == AuthState.error) {
          state = AuthState.unauthenticated;
        }
      });
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    ref.read(authTokenProvider.notifier).state = null;
    state = AuthState.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
