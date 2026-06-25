import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:customer_app/features/profile/data/profile_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ProfileRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    adapter = DioAdapter(dio: dio);
    repo = ProfileRepository(dio);
  });

  test('getMe parses the current user', () async {
    adapter.onGet('/users/me', (s) => s.reply(200, {
          'id': 'u1',
          'email': 'a@b.com',
          'fullName': 'Ada',
        }));

    final user = await repo.getMe();

    expect(user.id, 'u1');
    expect(user.email, 'a@b.com');
    expect(user.fullName, 'Ada');
  });

  test('updateProfile sends only the provided fields', () async {
    // Route matches a body with just fullName, proving the null-aware
    // entries (`'phone': ?phone`, `'avatarUrl': ?avatarUrl`) are dropped.
    adapter.onPatch(
      '/users/me',
      (s) => s.reply(200, {'id': 'u1', 'fullName': 'New Name'}),
      data: {'fullName': 'New Name'},
    );

    final user = await repo.updateProfile(fullName: 'New Name');

    expect(user.fullName, 'New Name');
  });

  test('updateProfile sends an empty body when nothing is provided', () async {
    adapter.onPatch('/users/me', (s) => s.reply(200, {'id': 'u1'}), data: {});

    final user = await repo.updateProfile();

    expect(user.id, 'u1');
  });
}
