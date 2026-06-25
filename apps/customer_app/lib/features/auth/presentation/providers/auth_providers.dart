import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';



import '../../../../core/network/api_client.dart';

import '../../../../core/realtime/socket_service.dart';

import '../../../../core/session/user_session_cleanup.dart';

import '../../../profile/data/profile_repository.dart';

import '../../data/datasources/auth_remote_datasource.dart';

import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/entities/user_entity.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../domain/usecases/login_usecase.dart';

import '../../domain/usecases/register_usecase.dart';



const _kAccessToken = 'access_token';

const _kRefreshToken = 'refresh_token';



final secureStorageProvider = Provider<FlutterSecureStorage>(

  (ref) => const FlutterSecureStorage(),

);



final authRepositoryProvider = Provider<AuthRepository>((ref) {

  return AuthRepositoryImpl(

    AuthRemoteDataSource(ref.watch(apiClientProvider)),

  );

});



final loginUseCaseProvider = Provider<LoginUseCase>(

  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),

);



final registerUseCaseProvider = Provider<RegisterUseCase>(

  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),

);



final currentUserProvider = StateProvider<UserEntity?>((ref) => null);



final authSessionProvider =

    StateNotifierProvider<AuthSessionNotifier, AsyncValue<void>>((ref) {

  return AuthSessionNotifier(ref);

});



class AuthSessionNotifier extends StateNotifier<AsyncValue<void>> {

  AuthSessionNotifier(this._ref) : super(const AsyncData(null));



  final Ref _ref;



  Future<bool> restoreSession() async {

    final storage = _ref.read(secureStorageProvider);

    final access = await storage.read(key: _kAccessToken);

    if (access == null || access.isEmpty) return false;



    _ref.read(authTokenProvider.notifier).state = access;



    try {

      await _syncProfileAndSocket();

      return true;

    } catch (_) {

      await clearLocalSession();

      return false;

    }

  }



  /// Switches to a new authenticated user: clears old caches, stores tokens, loads profile.

  Future<void> establishSession({

    required String accessToken,

    required String refreshToken,

  }) async {

    final storage = _ref.read(secureStorageProvider);

    final previousRefresh = await storage.read(key: _kRefreshToken);



    clearUserScopedData(_ref);



    if (previousRefresh != null &&

        previousRefresh.isNotEmpty &&

        previousRefresh != refreshToken) {

      try {

        await _ref

            .read(authRepositoryProvider)

            .logout(refreshToken: previousRefresh);

      } catch (_) {}

    }



    await storage.write(key: _kAccessToken, value: accessToken);

    await storage.write(key: _kRefreshToken, value: refreshToken);

    _ref.read(authTokenProvider.notifier).state = accessToken;



    await _syncProfileAndSocket();

  }



  Future<void> _syncProfileAndSocket() async {

    _ref.read(socketServiceProvider).disconnect();

    final user = await _ref.read(profileRepositoryProvider).getMe();

    _ref.read(currentUserProvider.notifier).state = user.toEntity();

    connectSocketFromRef(_ref);

  }



  /// Clears tokens without calling logout API (e.g. expired session on splash).

  Future<void> clearLocalSession() async {

    final storage = _ref.read(secureStorageProvider);

    await storage.delete(key: _kAccessToken);

    await storage.delete(key: _kRefreshToken);

    _ref.read(authTokenProvider.notifier).state = null;

    _ref.read(currentUserProvider.notifier).state = null;

    _ref.read(socketServiceProvider).disconnect();

    clearUserScopedData(_ref);

  }



  Future<void> logout() async {

    final storage = _ref.read(secureStorageProvider);

    final refresh = await storage.read(key: _kRefreshToken);

    if (refresh != null) {

      try {

        await _ref.read(authRepositoryProvider).logout(refreshToken: refresh);

      } catch (_) {}

    }

    await clearLocalSession();

  }

}



final authControllerProvider =

    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {

  return AuthController(ref);

});



class AuthController extends StateNotifier<AsyncValue<void>> {

  AuthController(this._ref) : super(const AsyncData(null));



  final Ref _ref;



  Future<void> login(String email, String password) async {

    state = const AsyncLoading();

    try {

      final result = await _ref.read(loginUseCaseProvider)(

        email: email,

        password: password,

      );

      await _ref.read(authSessionProvider.notifier).establishSession(

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

          );

      state = const AsyncData(null);

    } on AuthRepositoryException catch (e, st) {

      state = AsyncError(e, st);

    } catch (e, st) {

      state = AsyncError(e, st);

    }

  }



  Future<void> register(String email, String password, String fullName) async {

    state = const AsyncLoading();

    try {

      final result = await _ref.read(registerUseCaseProvider)(

        email: email,

        password: password,

        fullName: fullName,

      );

      await _ref.read(authSessionProvider.notifier).establishSession(

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

          );

      state = const AsyncData(null);

    } on AuthRepositoryException catch (e, st) {

      state = AsyncError(e, st);

    } catch (e, st) {

      state = AsyncError(e, st);

    }

  }



  Future<void> phoneRegister(String phone, String fullName) async {

    state = const AsyncLoading();

    try {

      final result = await _ref

          .read(authRepositoryProvider)

          .registerWithPhone(phone: phone, fullName: fullName);

      await _ref.read(authSessionProvider.notifier).establishSession(

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

          );

      state = const AsyncData(null);

    } on AuthRepositoryException catch (e, st) {

      state = AsyncError(e, st);

    } catch (e, st) {

      state = AsyncError(e, st);

    }

  }



  Future<void> phoneLogin(String phone, String code) async {

    state = const AsyncLoading();

    try {

      final result = await _ref

          .read(authRepositoryProvider)

          .verifyPhoneLoginOtp(phone: phone, code: code);

      await _ref.read(authSessionProvider.notifier).establishSession(

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

          );

      state = const AsyncData(null);

    } on AuthRepositoryException catch (e, st) {

      state = AsyncError(e, st);

    } catch (e, st) {

      state = AsyncError(e, st);

    }

  }

}


