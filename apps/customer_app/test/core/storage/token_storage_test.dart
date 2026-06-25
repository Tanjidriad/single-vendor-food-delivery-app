import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:customer_app/core/storage/token_storage.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage secure;
  late TokenStorage storage;

  setUp(() {
    secure = _MockSecureStorage();
    storage = TokenStorage(secure);
  });

  test('readAccessToken / readRefreshToken use the expected keys', () async {
    when(() => secure.read(key: 'access_token')).thenAnswer((_) async => 'a');
    when(() => secure.read(key: 'refresh_token')).thenAnswer((_) async => 'r');

    expect(await storage.readAccessToken(), 'a');
    expect(await storage.readRefreshToken(), 'r');
  });

  test('writeTokens persists both keys', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await storage.writeTokens(accessToken: 'a', refreshToken: 'r');

    verify(() => secure.write(key: 'access_token', value: 'a')).called(1);
    verify(() => secure.write(key: 'refresh_token', value: 'r')).called(1);
  });

  test('clear deletes both keys', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await storage.clear();

    verify(() => secure.delete(key: 'access_token')).called(1);
    verify(() => secure.delete(key: 'refresh_token')).called(1);
  });
}
