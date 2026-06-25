import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/features/orders/data/orders_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late OrdersRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    adapter = DioAdapter(dio: dio);
    repo = OrdersRepository(dio);
  });

  test('listOrders parses the payload into typed OrderModels', () async {
    adapter.onGet('/orders', (s) => s.reply(200, [
          {'id': 'o1', 'status': 'PLACED', 'grandTotal': 12.5},
          {'id': 'o2', 'status': 'DELIVERED'},
        ]));

    final orders = await repo.listOrders();

    expect(orders, hasLength(2));
    expect(orders.first.id, 'o1');
    expect(orders.first.grandTotal, 12.5);
    expect(orders.first.isActive, isTrue);
    expect(orders.last.isActive, isFalse);
  });

  test('listOrders tolerates a null body', () async {
    adapter.onGet('/orders', (s) => s.reply(200, null));
    expect(await repo.listOrders(), isEmpty);
  });

  test('getOrder fetches a single order by id', () async {
    adapter.onGet('/orders/o1', (s) => s.reply(200, {'id': 'o1', 'status': 'PENDING'}));

    final order = await repo.getOrder('o1');

    expect(order.status, 'PENDING');
    expect(order.raw['id'], 'o1');
  });

  test('placeOrder posts the body and returns the created order', () async {
    adapter.onPost(
      '/orders',
      (s) => s.reply(201, {'id': 'new'}),
      data: {'items': <dynamic>[]},
    );

    final res = await repo.placeOrder({'items': <dynamic>[]});

    expect(res['id'], 'new');
  });

  test('cancelOrder omits reason when null (null-aware map entry)', () async {
    // The route only matches an empty body, proving `{'reason': ?reason}`
    // drops the entry when reason is null.
    adapter.onPost('/orders/o1/cancel', (s) => s.reply(200, {'ok': true}), data: {});

    final res = await repo.cancelOrder('o1');

    expect(res['ok'], true);
  });

  test('cancelOrder includes reason when provided', () async {
    adapter.onPost(
      '/orders/o1/cancel',
      (s) => s.reply(200, {'ok': true}),
      data: {'reason': 'too slow'},
    );

    final res = await repo.cancelOrder('o1', reason: 'too slow');

    expect(res['ok'], true);
  });

  test('reorder posts to the reorder endpoint', () async {
    adapter.onPost('/orders/o1/reorder', (s) => s.reply(200, {'id': 'o2'}));
    expect((await repo.reorder('o1'))['id'], 'o2');
  });

  test('getOrder maps a 500 to a ServerFailure', () async {
    adapter.onGet('/orders/boom', (s) => s.reply(500, {'message': 'down'}));

    expect(repo.getOrder('boom'), throwsA(isA<ServerFailure>()));
  });

  test('getOrder throws a ServerFailure on an empty body', () async {
    adapter.onGet('/orders/empty', (s) => s.reply(200, null));

    expect(repo.getOrder('empty'), throwsA(isA<ServerFailure>()));
  });
}
