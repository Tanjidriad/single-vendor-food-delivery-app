import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:customer_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

DioException _dioError(int status, Object? data) => DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: status,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  late _MockRemote remote;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AuthRepositoryImpl(remote);
  });

  test('login maps tokens and user from the response', () async {
    when(() => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'user': {'id': 'u1', 'email': 'a@b.com'},
        });

    final result = await repo.login(email: 'a@b.com', password: 'pw');

    expect(result.accessToken, 'access');
    expect(result.refreshToken, 'refresh');
    expect(result.user.id, 'u1');
  });

  test('login throws AuthRepositoryException when tokens are missing', () async {
    when(() => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => {
          'user': {'id': 'u1'},
        });

    expect(
      () => repo.login(email: 'a@b.com', password: 'pw'),
      throwsA(isA<AuthRepositoryException>()),
    );
  });

  test('login surfaces the server message from a DioException', () async {
    when(() => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(_dioError(401, {'message': 'Invalid credentials'}));

    expect(
      () => repo.login(email: 'a@b.com', password: 'pw'),
      throwsA(
        predicate(
          (e) => e is AuthRepositoryException && e.toString() == 'Invalid credentials',
        ),
      ),
    );
  });

  test('register maps tokens and user', () async {
    when(() => remote.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
        )).thenAnswer((_) async => {
          'accessToken': 'a2',
          'refreshToken': 'r2',
          'user': {'id': 'u2'},
        });

    final result = await repo.register(
      email: 'a@b.com',
      password: 'pw',
      fullName: 'Ada',
    );

    expect(result.accessToken, 'a2');
    expect(result.user.id, 'u2');
  });

  test('sendPasswordResetOtp returns the dev code when present', () async {
    when(() => remote.sendOtp(
          email: any(named: 'email'),
          purpose: any(named: 'purpose'),
        )).thenAnswer((_) async => {'devCode': '123456'});

    expect(await repo.sendPasswordResetOtp(email: 'a@b.com'), '123456');
  });
}
